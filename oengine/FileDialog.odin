package oengine

import "core:fmt"
import "core:path/filepath"

import sdl "vendor:sdl2"
import ttf "vendor:sdl2/ttf"
import strs "core:strings"
import "core:thread"
import "nfd"

BUTTON_WIDTH :: 180
BUTTON_HEIGHT :: 30

fd_file_path :: proc() -> string {
    @static curr_dir: string;
    @static files: rl_FilePathList;
    curr_dir, files = fd_dir_and_files(string(rl_GetWorkingDirectory()));
    @static res_path: string;
    res_path = "";

    if (ttf.WasInit() == 0) {
        ttf.Init();
    }

    @static fd_font: ^ttf.Font;
    fd_font = ttf.OpenFont(strs.clone_to_cstring(str_add(OE_FONTS_PATH, "default_font.ttf")), 28);
    if (fd_font == nil) {
        dbg_log(str_add("Failed to load font: ", string(ttf.GetError())), DebugType.ERROR);
    } 
    defer ttf.CloseFont(fd_font);

    @(static) render: proc(^sdl.Renderer, ^bool);
    render = proc(renderer: ^sdl.Renderer, running: ^bool) {
        sdl.SetRenderDrawColor(renderer, gui_main_color.r, gui_main_color.g, gui_main_color.b, gui_main_color.a);
        sdl.RenderClear(renderer);

        sdl_draw_text(renderer, fd_font, string(curr_dir), 10, 10, 1, WHITE);
        if (sdl_button(renderer, "<", fd_font, 740, 10, 50, 25)) {
            curr_dir, files = fd_dir_and_files(filepath.dir(curr_dir));
        }

        for i in 0..<files.count {
            path := string(files.paths[i]);
            if (sdl_button(renderer, filepath.base(path), fd_font, 10, 45 + 35 * f32(i), 500, 25)) {
                if (rl_DirectoryExists(strs.clone_to_cstring(path))) {
                    curr_dir, files = fd_dir_and_files(path);
                } else {
                    res_path = path;
                    sdl_quit(running);
                }
            }
        }
    };


    window := sdl_create_window(800, 600, "Files");
    sdl_window(window, sdl_create_renderer(window), nil, render);

    return res_path;
}

fd_dir :: proc() -> string {
    @static curr_dir: string;
    @static files: rl_FilePathList;
    curr_dir, files = fd_dir_and_files(string(rl_GetWorkingDirectory()));
    @static res_path: string;
    res_path = "";

    if (ttf.WasInit() == 0) {
        ttf.Init();
    }

    @static fd_font: ^ttf.Font;
    fd_font = ttf.OpenFont(strs.clone_to_cstring(str_add(OE_FONTS_PATH, "default_font.ttf")), 28);
    if (fd_font == nil) {
        dbg_log(str_add("Failed to load font: ", string(ttf.GetError())), DebugType.ERROR);
    } 
    defer ttf.CloseFont(fd_font);

    @(static) render: proc(^sdl.Renderer, ^bool);
    render = proc(renderer: ^sdl.Renderer, running: ^bool) {
        sdl.SetRenderDrawColor(renderer, gui_main_color.r, gui_main_color.g, gui_main_color.b, gui_main_color.a);
        sdl.RenderClear(renderer);

        sdl_draw_text(renderer, fd_font, string(curr_dir), 10, 10, 1, WHITE);
        if (sdl_button(renderer, "<", fd_font, 740, 10, 50, 25)) {
            curr_dir, files = fd_dir_and_files(filepath.dir(curr_dir));
        }

        for i in 0..<files.count {
            path := string(files.paths[i]);
            if (sdl_button(renderer, filepath.base(path), fd_font, 10, 45 + 35 * f32(i), 500, 25)) {
                if (rl_DirectoryExists(strs.clone_to_cstring(path))) {
                    curr_dir, files = fd_dir_and_files(path);
                }
            }

            if (sdl_button(renderer, "select", fd_font, 800 - 110, 600 - 35, 100, 25)) {
                res_path = curr_dir;
                sdl_quit(running);
            }
        }
    };


    window := sdl_create_window(800, 600, "Files");
    sdl_window(window, sdl_create_renderer(window), nil, render);

    return res_path;
}

fd_dir_and_files :: proc(dir: string) -> (string, rl_FilePathList) {
    curr_dir, t := strs.replace_all(dir, "\\", "/");
    files := rl_LoadDirectoryFiles(strs.clone_to_cstring(curr_dir));

    for i in 0..<files.count {
        path, t := strs.replace_all(string(files.paths[i]), "\\", "/");
        files.paths[i] = strs.clone_to_cstring(path);
    }

    return curr_dir, files;
}

nfd_file :: proc() -> string {
    path: cstring;
    filters := [?]nfd.Filter_Item{ };
    args := nfd.Open_Dialog_Args{
        filter_list = raw_data(filters[:]),
        filter_count = len(filters),
    };
    result := nfd.OpenDialogU8_With(&path, &args);

    if (result == .Error) {
        return "";
    }

    res, ok := strs.replace_all(strs.clone_from_cstring(path), "\\", "/");
    return res;
}

nfd_folder :: proc() -> string {
    path: cstring;
    result := nfd.PickFolderU8(&path, "");

    if (result == .Error) {
        return "";
    }

    res, ok := strs.replace_all(strs.clone_from_cstring(path), "\\", "/");
    return res;
}
