//
// Created by liu86 on 2025/12/29.
//

#include "Window.h"
#include <SDL3/SDL.h>
#include <Logger.h>

namespace {
constexpr auto LOG_CHANNEL = "View";
}

namespace view {
Window::Window(const std::string& title, int width, int height)
{
    FunctionTracer tracer(LogLevel::DEBUG, LOG_CHANNEL);
    m_window = SDL_CreateWindow(title.c_str(),
                               width,
                               height,
                               0);
    if (!m_window) {
        LogError(LOG_CHANNEL).format("Failed to create window: {}", SDL_GetError());
        throw std::runtime_error("Failed to create SDL window");
    }
}
Window::~Window()
{
    if (m_window) {
        SDL_DestroyWindow(m_window);
        m_window = nullptr;
    }
}
} // namespace view