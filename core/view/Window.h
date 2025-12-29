//
// Created by liu86 on 2025/12/29.
//

#pragma once

#include <string>

struct SDL_Window;

namespace view {
class Window {
public:
    Window(const std::string& title, int width, int height);
    ~Window();

private:
    SDL_Window* m_window{nullptr};
};

} // namespace view
