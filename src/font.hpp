#pragma once

#include <sushi/mesh.hpp>
#include <sushi/shader.hpp>
#include <sushi/texture.hpp>

#include <msdfgen.h>
#include <msdfgen-ext.h>

#include <string>
#include <unordered_map>
#include <memory>

struct FontDeleter {
    void operator()(msdfgen::FontHandle* ptr) {
        msdfgen::destroyFont(ptr);
    }
};

class msdf_font {
public:
    static constexpr int TEX_SIZE = 512;

    struct glyph {
        const sushi::static_mesh* mesh;
        const sushi::texture_2d* texture;
        float advance;
        int width;
        int height;
    };

    msdf_font() = default;
    msdf_font(const std::string& filename);

    glyph get_glyph(int unicode) const;

private:
    struct glyph_def {
        sushi::static_mesh mesh;
        int texture_index;
        float advance;
        int width;
        int height;
    };

    bool load_glyph(int unicode) const;

    std::unique_ptr<msdfgen::FontHandle, FontDeleter> font;
    mutable std::unordered_map<int, glyph_def> glyphs;
    mutable std::vector<sushi::texture_2d> textures;
    mutable int current_u = 0;
    mutable int current_v = 0;
    mutable int advance_v = 0;
};
