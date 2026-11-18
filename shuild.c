// ONLR's build script. ONLR has no C code to compile: it puts the engine and the packages into the samples, starts the editor and runs the tests.
// Compile it once, and it compiles itself again when this file changes: cc shuild.c -o shuild && ./shuild
// It has no SHUC_ENABLE_INCREMENTAL or SHUC_COMPILE_DATABASE, which OpenECS's shuild.c has: they choose how modules compile, and ONLR compiles none.
#define SHU_IMPLEMENTATION
#include "dependencies/shuild/shuild.h"

#pragma region Setup

/// @brief What the build does, in groups, as OpenECS's shuild.c keeps it.
static struct
{
    // what the command line chooses
    struct
    {
        const char *openecs;  // the folder of OpenECS's release
        const char *love;     // LÖVE's executable
        const char *compiler; // compiles this file again when it changes
        bool editor;          // start the editor
        const char *project;  // the project's folder that the editor opens, or NULL
        bool test;            // run the samples' tests
        char **testedSamples; // the samples whose tests run, as the command line names them, or none for every sample
        int testedSampleCount;
        bool help;                     // print the help, and do nothing
        const char *badArgument;       // the first argument that cannot be read
        const char *badArgumentReason; // and why
    } FLAGS;

    // the samples' tests that ran, those that failed, and whether the editor's tests were left out
    struct
    {
        int run;
        int failed;
        bool skipped;
    } TESTS;
} CONFIG = {.FLAGS = {.openecs = "OpenECS/", .compiler = SHUM_HOST_WINDOWS || SHUM_HOST_MACOS ? "clang" : "gcc"}};

/// @brief The packages that a sample holds beside the engine, by the sample's name.
static const char *const SAMPLE_PACKAGES[][2] = {{"coinrun", "bump"}, {"physics", "physics"}, {"animation", "anim8"}, {"particles", "particles"}, {"tilemap", "sti"}, {"tweens", "flux"}, {"tweens", "tick"}, {"input", "baton"}, {"screen", "push"}, {"effects", "moonshine"}, {"audio", "audio"}, {"interface", "suit"}, {"interface", "push"}};

#pragma endregion Setup

static void ReadArguments(int argc, char **argv);
static void PrintUsage(void);
static void PutPackages(const char *path, SHUFileType type, void *data);
static void RunTests(void);
static void RunEditor(void);

int main(int argc, char **argv)
{
    ReadArguments(argc, argv);
    SHU_CompilerConfigureTry(CONFIG.FLAGS.compiler);

    // a changed shuild.c is compiled again and run with the same arguments, so a bad argument is reported after it, by the new program
    SHU_UtilAutomate(argc, argv);

    if (CONFIG.FLAGS.badArgument != NULL)
    {
        PrintUsage();
        SHU_UtilFail("%s: " SHUM_LOG_VALUE("%s"), CONFIG.FLAGS.badArgumentReason, CONFIG.FLAGS.badArgument);
    }

    if (CONFIG.FLAGS.help)
    {
        PrintUsage();
        return 0;
    }

    SHU_UtilListDirectory("samples/", false, PutPackages, NULL);

    if (CONFIG.FLAGS.test)
    {
        RunTests();
    }

    if (CONFIG.FLAGS.editor)
    {
        RunEditor();
    }

    return 0;
}

static void PrintUsage(void)
{
    printf("Usage: ./shuild [FLAG...]\n\n"
           "Puts the engine and the packages into every sample, as a project holds them, so LÖVE runs a sample: love samples/coinrun\n\n"
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
    if (CONFIG.FLAGS.badArgument == NULL)
    {
        CONFIG.FLAGS.badArgumentReason = reason;
        CONFIG.FLAGS.badArgument = argument;
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
            CONFIG.FLAGS.openecs = AsFolder(argv[++i]);
        }
        else if (!strcmp(flag, "-l") || !strcmp(flag, "--love"))
        {
            CONFIG.FLAGS.love = argv[++i];
        }
        else if (!strcmp(flag, "-c") || !strcmp(flag, "--compiler"))
        {
            CONFIG.FLAGS.compiler = argv[++i];
        }
        else if (!strcmp(flag, "-e") || !strcmp(flag, "--editor"))
        {
            CONFIG.FLAGS.editor = true;

            if (hasNext)
            {
                CONFIG.FLAGS.project = argv[++i];
            }
        }
        else if (!strcmp(flag, "-t") || !strcmp(flag, "--test"))
        {
            CONFIG.FLAGS.test = true;
            CONFIG.FLAGS.testedSamples = &argv[i + 1];

            while (i + 1 < argc && argv[i + 1][0] != '-')
            {
                i++;
                CONFIG.FLAGS.testedSampleCount++;

                if (SHU_UtilFileExists(SHU_UtilFormat("samples/%s/", argv[i])) != SHUFileType_Directory)
                {
                    NoteBadArgument("No sample is named", argv[i]);
                    return;
                }
            }
        }
        else if (!strcmp(flag, "-h") || !strcmp(flag, "--help"))
        {
            CONFIG.FLAGS.help = true;
        }
        else
        {
            NoteBadArgument(flag[0] == '-' ? "Unknown flag" : "Unknown argument", flag);
            return;
        }
    }

    if (CONFIG.FLAGS.love == NULL)
    {
        const char *named = getenv("LOVE");
        CONFIG.FLAGS.love = named != NULL && named[0] != '\0' ? named : "love";
    }
}

/// @brief Makes a folder a copy of another: what it held is deleted first.
static void CopyFolder(const char *from, const char *to)
{
    SHU_UtilDeleteFile(to);
    SHU_UtilCopyFile(from, to);
}

/// @brief Gives a sample its packages in packages/, as a project holds them: the engine, the packages that SAMPLE_PACKAGES names for it,
/// and the tests' helper. git ignores the copies.
static void PutPackages(const char *path, SHUFileType type, void *data)
{
    (void)data;

    if (type != SHUFileType_Directory)
    {
        return;
    }

    char *packages = SHU_UtilFormat("%spackages/", path);
    CopyFolder("packages/onlr/", SHU_UtilFormat("%sonlr/", packages));
    SHU_UtilCopyFile("samples/check.lua", packages);

    // the sample's name is its folder's, which ends with / or, on Windows, with a backslash
    usz end = strlen(path);

    while (end > 0 && (path[end - 1] == '/' || path[end - 1] == '\\'))
    {
        end--;
    }

    usz start = end;

    while (start > 0 && path[start - 1] != '/' && path[start - 1] != '\\')
    {
        start--;
    }

    char *name = SHU_UtilFormat("%.*s", (int)(end - start), path + start);

    for (usz i = 0; i < sizeof(SAMPLE_PACKAGES) / sizeof(SAMPLE_PACKAGES[0]); i++)
    {
        if (!strcmp(name, SAMPLE_PACKAGES[i][0]))
        {
            CopyFolder(SHU_UtilFormat("packages/%s/", SAMPLE_PACKAGES[i][1]), SHU_UtilFormat("%s%s/", packages, SAMPLE_PACKAGES[i][1]));
        }
    }
}

/// @brief Gives the path of OpenECS's executable, or NULL if OpenECS's release is not in its folder.
static const char *OpenECS(void)
{
    char *program = SHU_UtilFormat("%sOpenECS%s", CONFIG.FLAGS.openecs, SHUM_HOST_WINDOWS ? ".exe" : "");
    return SHU_UtilFileExists(program) == SHUFileType_Regular ? SHU_UtilGetPath(program) : NULL;
}

static void RunEditor(void)
{
    const char *openecs = OpenECS();

    if (openecs == NULL)
    {
        SHU_UtilFail("OpenECS's release is not in " SHUM_LOG_PATH("%s") "; unpack it there, or name its folder with " SHUM_LOG_COMMAND("-o") ".", CONFIG.FLAGS.openecs);
    }

    // a project's folder loses its last separator: on Windows, a backslash before a closing quote would keep the quote in the argument
    char *project = "";

    if (CONFIG.FLAGS.project != NULL)
    {
        project = SHU_UtilGetPath(CONFIG.FLAGS.project);
        usz length = strlen(project);

        while (length > 1 && (project[length - 1] == '/' || project[length - 1] == '\\'))
        {
            project[--length] = '\0';
        }

        project = SHU_UtilFormat(" \"%s\"", project);
    }

    // cmd, which runs the command on Windows, takes away its first and last quotes when it has more than two, so the command gets a pair of its own
    const char *wrap = SHUM_HOST_WINDOWS ? "\"" : "";
    SHU_UtilRun("%s\"%s\" --preset \"%s\"%s%s", wrap, openecs, SHU_UtilGetPath("preset.lua"), project, wrap);
}

static bool IsTested(const char *name)
{
    for (int i = 0; i < CONFIG.FLAGS.testedSampleCount; i++)
    {
        if (!strcmp(CONFIG.FLAGS.testedSamples[i], name))
        {
            return true;
        }
    }

    return CONFIG.FLAGS.testedSampleCount == 0;
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
    CONFIG.TESTS.run++;

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
        CONFIG.TESTS.failed++;
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
    const char *settings = SHU_UtilFormat("LOVE=\"%s\" SDL_VIDEODRIVER=offscreen ALSOFT_DRIVERS=null timeout 120", CONFIG.FLAGS.love);

    if (SHU_UtilFileExists(SHU_UtilFormat("%seditortest.lua", path)) == SHUFileType_Regular)
    {
        const char *openecs = OpenECS();

        if (openecs == NULL)
        {
            CONFIG.TESTS.skipped = true;
        }
        else
        {
            char *work = SHU_UtilFormat("build/tests/work/%s/", name);
            char *log = SHU_UtilFormat("build/tests/%s.editor.log", name);
            CopyFolder(path, work);
            // What the editor kept for the sample on this computer, such as snapping, is not the sample's.
            SHU_UtilDeleteFile(SHU_UtilFormat("%s.onlr/", work));
            bool passed = SHU_UtilRunTry("cd \"%s\" && %s \"%s\" --test editortest.lua > \"%s\" 2>&1", SHU_UtilGetPath(work), settings, openecs, SHU_UtilGetPath(log)) == 0;
            NoteTest(name, ", the editor's test", passed, log);
        }
    }

    if (SHU_UtilFileExists(SHU_UtilFormat("%stest.lua", path)) == SHUFileType_Regular)
    {
        char *log = SHU_UtilFormat("build/tests/%s.log", name);
        bool passed = SHU_UtilRunTry("%s \"%s\" \"%s\" --test > \"%s\" 2>&1", settings, CONFIG.FLAGS.love, SHU_UtilGetPath(path), SHU_UtilGetPath(log)) == 0;
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

    if (CONFIG.TESTS.skipped)
    {
        SHU_UtilWarn("the editor's tests are skipped: OpenECS's release is not in " SHUM_LOG_PATH("%s") ".", CONFIG.FLAGS.openecs);
    }

    if (CONFIG.TESTS.failed > 0)
    {
        SHU_UtilFail("%d of %d tests failed.", CONFIG.TESTS.failed, CONFIG.TESTS.run);
    }

    SHU_UtilLog("all %d tests passed.", CONFIG.TESTS.run);
}
