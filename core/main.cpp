#include "Logger.h"
#include <SDL3/SDL.h>
#include <argparse/argparse.hpp>
#include "view/Window.h"

int main(int argc, char* argv[])
{
    Logger::setLogLevel(LogLevel::DEBUG);
    Logger::setPrintLevel(LogLevel::DEBUG);
    Logger::setFileSizeThreshold(10 * 1024 * 1024); // 10 MB
#ifdef DEBUG_MODE
    Logger::setLogPath(PROJECT_ROOT_DIR "/logs");
#else
    Logger::setLogPath("logs");
#endif

    FunctionTracer tracer(LogLevel::DEBUG);

    argparse::ArgumentParser program("GameScrcpyCore");

    if (!SDL_Init(SDL_INIT_VIDEO|SDL_INIT_AUDIO)) {
        LogError() << "Failed to initialize SDL: " << SDL_GetError();
        return -1;
    }

    auto window = std::make_unique<view::Window>("GameScrcpyCore", 800, 600);

    SDL_Event ev;
    bool running = true;
    while (running) {
        while (SDL_PollEvent(&ev)) {
            if (ev.type == SDL_EVENT_QUIT) {
                running = false;
            }
        }
    }

    SDL_Quit();
    return 0;
}