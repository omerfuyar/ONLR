// A panel type in C: it shows how long it has been open, drawn with the draw plugin.
// It shows what a native plugin does: ECSPlugin_Init, a panel type, a timer, and functions of another plugin, from its definition header.

#include "OpenECS.h" // the plugin interface: every type and function of OpenECS that plugins use
#include "draw.h"    // the functions of the draw plugin, written by OpenECS --definitions; the release has it in include/

#include <stdio.h>
#include <stdlib.h>

/// @brief The plugin, and the functions of draw it looked up.
static struct
{
    ECSPlugin plugin;
    DrawFunctions draw;
} PULSE = {0};

/// @brief A panel's state: its panel, its timer and the seconds it has been open.
typedef struct PulsePanel
{
    ECSPanel panel;
    ECSTimer timer;
    i32 seconds;
} PulsePanel;

// runs each second: the panel counts, and asks to be drawn again
static void PulseTick(void *data)
{
    PulsePanel *pulse = data;
    pulse->seconds++;
    ECSPanel_Redraw(pulse->panel);
}

static SHUResult PulseCreate(ECSPanel panel, const ECSValue *savedState, u32 version, void **retState)
{
    (void)savedState;
    (void)version;

    PulsePanel *pulse = calloc(1, sizeof(PulsePanel));

    if (pulse == nullptr)
    {
        return SHUResult_ErrAllocation;
    }

    pulse->panel = panel;

    // the timer belongs to the plugin, so the panel stops it when it closes
    SHU_ReturnResult(ECSTimer_Start(PULSE.plugin, &pulse->timer, 1.0, true, PulseTick, pulse), free(pulse););
    *retState = pulse;
    return SHUResult_Ok;
}

static void PulseDestroy(void *state)
{
    PulsePanel *pulse = state;
    ECSTimer_Stop(&pulse->timer);
    free(pulse);
}

// positions and sizes are in layout units, which draw turns into the surface's pixels
static void PulseDraw(void *state, ECSSurface *surface, f64 seconds)
{
    (void)seconds;
    PulsePanel *pulse = state;
    ECSColor background = 0;
    ECSColor accent = 0;

    // colours of the theme, so the panel follows dark and light
    (void)ECSColor_Parse("background", &background);
    (void)ECSColor_Parse("accent", &accent);

    char text[64];
    snprintf(text, sizeof(text), "Open for %d seconds", pulse->seconds);

    f32 width = (f32)surface->width / surface->scale;
    f32 height = (f32)surface->height / surface->scale;
    f32 size = 16.0f + (f32)(pulse->seconds % 2) * 2.0f;

    PULSE.draw.fill(surface, 0.0f, 0.0f, width, height, background);
    PULSE.draw.circle(surface, width / 2.0f, height / 2.0f - 40.0f, size, 0.0f, accent);

    // a function that can fail outside its caller gives why in its last parameter, and returns nothing
    const char *error = nullptr;
    void *font = PULSE.draw.font("ui", &error);
    if (font != nullptr)
    {
        PULSE.draw.text(surface, font, text, 16.0f, height / 2.0f, 18.0f, accent);
    }
}

// OpenECS calls it once, after it loads the library; a plugin registers everything here
SHUResult ECSPlugin_Init(ECSPlugin plugin)
{
    PULSE.plugin = plugin;

    // looks up every function of draw with the signature it was written for, so a draw of another version is found out here
    SHU_ReturnResult(DrawFunctions_Get(plugin, &PULSE.draw));

    const ECSPanelTypeDesc pulse = {
        .name = "panel", // the local name; presets name it "pulse_c.panel"
        .title = "Pulse",
        .Create = PulseCreate,
        .Destroy = PulseDestroy,
        .Draw = PulseDraw,
    };

    ECS_LogInfo(plugin, "The pulse plugin loads.");
    return ECSPanelType_Register(plugin, &pulse);
}
