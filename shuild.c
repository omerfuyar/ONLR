// ONLR's build script. ONLR has no C code to compile: it puts the engine into the samples, starts the editor and runs the tests.
// Compile it once, and it compiles itself again when this file changes: cc shuild.c -o shuild && ./shuild
#define SHU_IMPLEMENTATION
#include "dependencies/shuild/shuild.h"

/// @brief What the flags choose.
static struct
{
    const char *openecs;  // the folder of OpenECS's release
    const char *love;     // LÖVE's executable
    const char *compiler; // compiles this file again when it changes
    bool editor;          // start the editor
    const char *project;  // the project's folder that the editor opens, or NULL
    bool test;            // run the samples' tests
    char **tested;        // the samples whose tests run, or none for every sample
    int testedCount;
    bool help;
    const char *badArgument; // the first argument that cannot be read, and why
    const char *badArgumentReason;

    // the tests that ran, those that failed, and whether the editor's tests were left out
    int run;
    int failed;
    bool skipped;
} CONFIG = {.openecs = "OpenECS/", .love = NULL, .compiler = SHUM_HOST_WINDOWS ? "clang" : "gcc"};

static void PrintUsage(void)
{
    printf("Usage: ./shuild [FLAG...]\n\n"
           "Puts the engine into every sample, as a project holds it, so LÖVE runs a sample: love samples/coinrun\n\n"
           "Flags:\n"
           "  -e, --editor [PROJECT]  Then start the editor, on a project's folder if one is named\n"
           "  -t, --test [SAMPLE...]  Then run the tests of the samples named, such as coinrun, or of every sample.\n"
           "                          Prints pass or FAIL for each\n"
           "  -o, --openecs FOLDER    The folder of OpenECS's release, from this folder: OpenECS/ (the default)\n"
           "  -l, --love PROGRAM      LÖVE 11.5's executable: what the variable LOVE names, or love (the default)\n"
           "  -c, --compiler CC       The compiler that compiles this file again when it changes: gcc (the default), or clang\n"
           "  -h, --help              Show this help\n");
}

/// @brief Notes the first argument that cannot be read. main reports it, after shuild.c is compiled again if it changed.
static void NoteBadArgument(const char *reason, const char *argument)
{
    if (CONFIG.badArgument == NULL)
    {
        CONFIG.badArgumentReason = reason;
        CONFIG.badArgument = argument;
    }
}

/// @brief Gives a folder's path with a slash at its end, as the paths that are joined to it need.
static const char *AsFolder(const char *folder)
{
    return folder[0] != '\0' && folder[strlen(folder) - 1] == '/' ? folder : SHU_UtilFormat("%s/", folder);
}

/// @brief Reads every flag into CONFIG.
static void ReadArguments(int argc, char **argv)
{
    for (int i = 1; i < argc; i++)
    {
        const char *flag = argv[i];
        bool hasNext = i + 1 < argc && argv[i + 1][0] != '-';
        bool takesValue = !strcmp(flag, "-o") || !strcmp(flag, "--openecs") || !strcmp(flag, "-l") || !strcmp(flag, "--love") || !strcmp(flag, "-c") || !strcmp(flag, "--compiler");

        if (takesValue && i + 1 == argc)
        {
            NoteBadArgument("A value is missing after the flag", flag);
            return;
        }

        if (!strcmp(flag, "-o") || !strcmp(flag, "--openecs"))
        {
            CONFIG.openecs = AsFolder(argv[++i]);
        }
        else if (!strcmp(flag, "-l") || !strcmp(flag, "--love"))
        {
            CONFIG.love = argv[++i];
        }
        else if (!strcmp(flag, "-c") || !strcmp(flag, "--compiler"))
        {
            CONFIG.compiler = argv[++i];
        }
        else if (!strcmp(flag, "-e") || !strcmp(flag, "--editor"))
        {
            CONFIG.editor = true;

            if (hasNext)
            {
                CONFIG.project = argv[++i];
            }
        }
        else if (!strcmp(flag, "-t") || !strcmp(flag, "--test"))
        {
            CONFIG.test = true;
            CONFIG.tested = argv + i + 1;

            while (i + 1 < argc && argv[i + 1][0] != '-')
            {
                i++;
                CONFIG.testedCount++;

                if (SHU_UtilFileExists(SHU_UtilFormat("samples/%s/", argv[i])) != SHUFileType_Directory)
                {
                    NoteBadArgument("No such sample", argv[i]);
                    return;
                }
            }
        }
        else if (!strcmp(flag, "-h") || !strcmp(flag, "--help"))
        {
            CONFIG.help = true;
        }
        else
        {
            NoteBadArgument(flag[0] == '-' ? "Unknown flag" : "Unknown argument", flag);
            return;
        }
    }

    if (CONFIG.love == NULL)
    {
        const char *named = getenv("LOVE");
        CONFIG.love = named != NULL && named[0] != '\0' ? named : "love";
    }
}

/// @brief Makes a folder a copy of another: what it held is deleted first.
static void CopyFolder(const char *from, const char *to)
{
    SHU_UtilDeleteFile(to);
    SHU_UtilCopyFile(from, to);
}

/// @brief Gives a sample the engine in packages/onlr/, as a project holds it, and the tests' helper. git ignores both copies.
static void PutEngine(const char *path, SHUFileType type, void *data)
{
    (void)data;

    if (type != SHUFileType_Directory)
    {
        return;
    }

    char *packages = SHU_UtilFormat("%spackages/", path);
    CopyFolder("engine/", SHU_UtilFormat("%sonlr/", packages));
    SHU_UtilCopyFile("samples/check.lua", packages);
}

/// @brief Gives the path of OpenECS's executable, or NULL if OpenECS's release is not in its folder.
static const char *OpenECS(void)
{
    char *program = SHU_UtilFormat("%sOpenECS%s", CONFIG.openecs, SHUM_HOST_WINDOWS ? ".exe" : "");
    return SHU_UtilFileExists(program) == SHUFileType_Regular ? SHU_UtilGetPath(program) : NULL;
}

static void RunEditor(void)
{
    const char *openecs = OpenECS();

    if (openecs == NULL)
    {
        SHU_UtilFail("OpenECS's release is not in " SHUM_LOG_PATH("%s") "; unpack it there, or name its folder with " SHUM_LOG_COMMAND("-o") ".", CONFIG.openecs);
    }

    const char *project = CONFIG.project != NULL ? SHU_UtilFormat(" \"%s\"", SHU_UtilGetPath(CONFIG.project)) : "";
    SHU_UtilRun("\"%s\" --preset \"%s\"%s", openecs, SHU_UtilGetPath("preset.lua"), project);
}

static bool IsTested(const char *name)
{
    for (int i = 0; i < CONFIG.testedCount; i++)
    {
        if (!strcmp(CONFIG.tested[i], name))
        {
            return true;
        }
    }

    return CONFIG.testedCount == 0;
}

/// @brief Prints the end of a failed test's log, without what OpenAL Soft says of the missing sound device.
static void PrintLogEnd(const char *text)
{
    const char *start = text + strlen(text);

    for (int lines = 0; start > text && lines < 40; start--)
    {
        lines += start[-1] == '\n';
    }

    printf("%s\n", start);
}

/// @brief Counts a test, and prints pass or FAIL for it, with the lines that it reports with "report: ", or the end of its log.
static void NoteTest(const char *name, const char *kind, bool passed, const char *log)
{
    SHUSlice output = SHU_UtilReadFile(log);
    CONFIG.run++;

    if (passed)
    {
        printf("pass %s%s\n", name, kind);

        for (const char *line = output.data; line != NULL && *line != '\0'; line = strchr(line, '\n') != NULL ? strchr(line, '\n') + 1 : NULL)
        {
            if (!strncmp(line, "report: ", 8))
            {
                const char *end = strchr(line, '\n');
                printf("  %s: %.*s\n", name, (int)((end != NULL ? end : line + strlen(line)) - line - 8), line + 8);
            }
        }
    }
    else
    {
        CONFIG.failed++;
        printf("FAIL %s%s\n", name, kind);
        PrintLogEnd(output.data);
    }

    fflush(stdout);
    free(output.data);
}

/// @brief Runs a sample's tests. Its test of the engine is its test.lua: LÖVE runs the sample with --test and SDL's offscreen driver,
/// and the sample checks itself. Its test of the editor is its editortest.lua, an OpenECS test, which runs on a copy of the sample,
/// since it writes the sample's files.
static void TestSample(const char *path, SHUFileType type, void *data)
{
    (void)data;

    if (type != SHUFileType_Directory)
    {
        return;
    }

    // the sample's name: its folder's, without the separator at its end
    const char *end = path + strlen(path) - 1;
    const char *start = end;

    while (start > path && start[-1] != '/' && start[-1] != SHUM_PATH_SEPARATOR)
    {
        start--;
    }

    char *name = SHU_UtilFormat("%.*s", (int)(end - start), start);

    if (!IsTested(name))
    {
        return;
    }

    // the offscreen driver gives LÖVE a window that no screen shows, and OpenAL Soft's null driver needs no sound device.
    // A test that never ends is stopped after two minutes
    const char *settings = SHU_UtilFormat("LOVE=\"%s\" SDL_VIDEODRIVER=offscreen ALSOFT_DRIVERS=null timeout 120", CONFIG.love);

    if (SHU_UtilFileExists(SHU_UtilFormat("%seditortest.lua", path)) == SHUFileType_Regular)
    {
        const char *openecs = OpenECS();

        if (openecs == NULL)
        {
            CONFIG.skipped = true;
        }
        else
        {
            char *work = SHU_UtilFormat("build/tests/work/%s/", name);
            char *log = SHU_UtilFormat("build/tests/%s.editor.log", name);
            CopyFolder(path, work);
            bool passed = SHU_UtilRunTry("cd \"%s\" && %s \"%s\" --test editortest.lua > \"%s\" 2>&1", SHU_UtilGetPath(work), settings, openecs, SHU_UtilGetPath(log)) == 0;
            NoteTest(name, ", the editor's test", passed, log);
        }
    }

    if (SHU_UtilFileExists(SHU_UtilFormat("%stest.lua", path)) == SHUFileType_Regular)
    {
        char *log = SHU_UtilFormat("build/tests/%s.log", name);
        bool passed = SHU_UtilRunTry("%s \"%s\" \"%s\" --test > \"%s\" 2>&1", settings, CONFIG.love, SHU_UtilGetPath(path), SHU_UtilGetPath(log)) == 0;
        NoteTest(name, "", passed, log);
    }
}

static void RunTests(void)
{
    if (SHUM_HOST_WINDOWS)
    {
        SHU_UtilFail("the tests run on Linux only: they need SDL's offscreen driver.");
    }

    SHU_UtilCreateDirectory("build/tests/work/");
    SHU_UtilListDirectory("samples/", false, TestSample, NULL);

    if (CONFIG.skipped)
    {
        SHU_UtilWarn("the editor's tests are skipped: OpenECS's release is not in " SHUM_LOG_PATH("%s") ".", CONFIG.openecs);
    }

    if (CONFIG.failed > 0)
    {
        SHU_UtilFail("%d of %d tests failed.", CONFIG.failed, CONFIG.run);
    }

    SHU_UtilLog("all %d tests passed.", CONFIG.run);
}

int main(int argc, char **argv)
{
    ReadArguments(argc, argv);
    SHU_CompilerConfigureTry(CONFIG.compiler);

    // a changed shuild.c is compiled again and run with the same arguments, so a bad argument is reported after it, by the new program
    SHU_UtilAutomate(argc, argv);

    if (CONFIG.badArgument != NULL)
    {
        PrintUsage();
        SHU_UtilFail("%s: " SHUM_LOG_VALUE("%s"), CONFIG.badArgumentReason, CONFIG.badArgument);
    }

    if (CONFIG.help)
    {
        PrintUsage();
        return 0;
    }

    SHU_UtilListDirectory("samples/", false, PutEngine, NULL);

    if (CONFIG.test)
    {
        RunTests();
    }

    if (CONFIG.editor)
    {
        RunEditor();
    }

    return 0;
}
