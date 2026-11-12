// The build of the tool's plugins in C. Each folder of plugins/ with C files becomes a library in that folder: lib<name>.so on Linux, <name>.dll on Windows.
// Compile it once, and it compiles itself again when this file changes: cc shuild.c -o shuild && ./shuild
#define SHU_IMPLEMENTATION
#include "dependencies/shuild/shuild.h"

/// @brief What the flags choose.
static struct
{
    const char *openecs;  // the folder of OpenECS's release, whose include/ holds the plugin interface
    const char *compiler; // a cross compiler, such as x86_64-w64-mingw32-clang, builds for Windows
    bool help;
    const char *badArgument; // the first argument that cannot be read, and why
    const char *badArgumentReason;
} CONFIG = {.openecs = "OpenECS/", .compiler = SHUM_HOST_WINDOWS ? "clang" : "gcc"};

static void PrintUsage(void)
{
    printf("Usage: ./shuild [FLAG...]\n\n"
           "Builds each folder of plugins/ with C files into a library in that folder.\n\n"
           "Flags:\n"
           "  -o, --openecs FOLDER  The folder of OpenECS's release, from this folder: OpenECS/ (the default)\n"
           "  -c, --compiler CC     The compiler: gcc (the default), clang, or on Windows LLVM-MinGW's clang (the default there),\n"
           "                        as OpenECS is built with. A cross compiler, such as x86_64-w64-mingw32-clang, builds for Windows\n"
           "  -h, --help            Show this help\n");
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

/// @brief Reads every flag into CONFIG.
static void ReadArguments(int argc, char **argv)
{
    for (int i = 1; i < argc; i++)
    {
        const char *flag = argv[i];
        bool takesValue = !strcmp(flag, "-o") || !strcmp(flag, "--openecs") || !strcmp(flag, "-c") || !strcmp(flag, "--compiler");

        if (takesValue && i + 1 == argc)
        {
            NoteBadArgument("A value is missing after the flag", flag);
            return;
        }

        if (!strcmp(flag, "-o") || !strcmp(flag, "--openecs"))
        {
            // the folder's paths are joined to it, so it ends with a slash
            const char *folder = argv[++i];
            CONFIG.openecs = folder[0] != '\0' && folder[strlen(folder) - 1] == '/' ? folder : SHU_UtilFormat("%s/", folder);
        }
        else if (!strcmp(flag, "-c") || !strcmp(flag, "--compiler"))
        {
            CONFIG.compiler = argv[++i];
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
}

static void FindCode(const char *path, SHUFileType type, void *data)
{
    *(bool *)data = *(bool *)data || (type == SHUFileType_Regular && SHU_UtilMatch(path, "*.c"));
}

/// @brief Builds a folder of plugins/ into a library in that folder, if it has C files.
static void BuildPlugin(const char *path, SHUFileType type, void *data)
{
    (void)data;
    bool code = false;

    if (type == SHUFileType_Directory)
    {
        SHU_UtilListDirectory(path, false, FindCode, &code);
    }

    if (!code)
    {
        return;
    }

    // the folder's name, without the separator at its end
    const char *end = path + strlen(path) - 1;
    const char *start = end;

    while (start > path && start[-1] != '/' && start[-1] != SHUM_PATH_SEPARATOR)
    {
        start--;
    }

    char *name = SHU_UtilFormat("%.*s", (int)(end - start), start);

    SHU_Module(name, NULL, SHUModuleType_LibraryDynamic, path)
    {
        SHU_CompilerClearFlags();
        SHU_CompilerAddFlags(SHUM_FLAGS_STANDARD_C23, SHUM_FLAGS_WARNING_MID, SHUM_FLAGS_OPTIMIZATION_MID, "-fvisibility=hidden");
        SHU_ModuleAddSourceFiles(path);

        // the plugin sees only OpenECS's plugin interface, and the headers of the standard plugins beside it, such as draw.h
        SHU_ModuleAddIncludeDirectories(SHU_UtilFormat("%sinclude/", CONFIG.openecs));

        // a DLL cannot leave OpenECS's functions to be found when it is loaded, so it links OpenECS's import library, which the release has in lib/.
        // Elsewhere OpenECS's functions are found when the library is loaded, in the program that loads it
        if (SHU_CompilerGetTarget() == SHUPlatform_Windows)
        {
            SHU_ModuleAddLibraryDirectories(SHU_UtilFormat("%slib/", CONFIG.openecs));
            SHU_ModuleLinkLibraries("OpenECS");
        }
    }
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

    if (SHU_UtilFileExists(SHU_UtilFormat("%sinclude/OpenECS.h", CONFIG.openecs)) != SHUFileType_Regular)
    {
        SHU_UtilFail("OpenECS's release is not in " SHUM_LOG_PATH("%s") "; unpack it there, or name its folder with " SHUM_LOG_COMMAND("-o") ".", CONFIG.openecs);
    }

    SHU_UtilListDirectory("plugins/", false, BuildPlugin, NULL);
    return 0;
}
