#include "font.hpp"

#include <iostream>
#include <fstream>
#include <stdexcept>
#include <string>
#include <vector>

namespace { // static

msdfgen::FreetypeHandle* font_init() {
    static const auto ft = msdfgen::initializeFreetype();
    return ft;
}

} // static

msdf_font::msdf_font(const std::string& fontname) {
    auto ft = font_init();

    if (!ft) {
        throw std::runtime_error("Failed to initialize FreeType.");
    }

    font = decltype(font)(msdfgen::loadFont(ft, fontname.c_str()));

    if (!font) {
        throw std::runtime_error("Failed to load font "+fontname+".");
    }
}

msdf_font::glyph msdf_font::get_glyph(int unicode) const {
    auto iter = glyphs.find(unicode);

    if (iter == end(glyphs)) {
        if (!load_glyph(unicode)) {
            return {nullptr, nullptr, 0, 0, 0};
        }
        iter = glyphs.find(unicode);
    }

    auto& def = iter->second;

    return { &def.mesh, &textures[def.texture_index], def.advance, def.width, def.height };
}

bool msdf_font::load_glyph(int unicode) const {
    msdfgen::Shape shape;
    double advance;

    if (!msdfgen::loadGlyph(shape, font.get(), unicode, &advance)) {
        return false;
    }

    shape.normalize();
    msdfgen::edgeColoringSimple(shape, 3.0);

    double left = 0, bottom = 0, right = 0, top = 0;
    shape.bounds(left, bottom, right, top);

    left -= 1;
    bottom -= 1;
    right += 1;
    top += 1;

    auto width = int(right - left + 1);
    auto height = int(top - bottom + 1);

    msdfgen::Bitmap<msdfgen::FloatRGB> msdf(width, height);
    msdfgen::generateMSDF(msdf, shape, 4.0, 1.0, msdfgen::Vector2(-left, -bottom));

    std::vector<unsigned char> pixels;
    pixels.reserve(4 * msdf.width() * msdf.height());
    for (int y = 0; y < msdf.height(); ++y) {
        for (int x = 0; x < msdf.width(); ++x) {
            pixels.push_back(msdfgen::clamp(int(msdf(x, y).r * 0x100), 0xff));
            pixels.push_back(msdfgen::clamp(int(msdf(x, y).g * 0x100), 0xff));
            pixels.push_back(msdfgen::clamp(int(msdf(x, y).b * 0x100), 0xff));
            pixels.push_back(255);
        }
    }

    double em;
    msdfgen::getFontScale(em, font.get());

    left /= em;
    right /= em;
    bottom /= em;
    top /= em;
    advance /= em;

    auto g = glyph_def{};

    if (current_u + width > TEX_SIZE) {
        current_u = 0;
        current_v += advance_v;
        advance_v = 0;
    }

    if (textures.empty() || current_v + height > TEX_SIZE) {
        current_u = 0;
        current_v = 0;
        advance_v = 0;

        auto texture = sushi::texture_2d{};
        texture.handle = sushi::make_unique_texture();
        texture.width = TEX_SIZE;
        texture.height = TEX_SIZE;

        glBindTexture(GL_TEXTURE_2D, texture.handle.get());
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, TEX_SIZE, TEX_SIZE, 0, GL_RGBA, GL_UNSIGNED_BYTE, nullptr);

        g.texture_index = textures.size();
        textures.push_back(std::move(texture));
    } else {
        g.texture_index = textures.size() - 1;
        glBindTexture(GL_TEXTURE_2D, textures.back().handle.get());
    }

    glTexSubImage2D(
        GL_TEXTURE_2D, 0, current_u, current_v, msdf.width(), msdf.height(), GL_RGBA, GL_UNSIGNED_BYTE, &pixels[0]);

    const auto u = double(current_u) / double(TEX_SIZE);
    const auto v = double(current_v) / double(TEX_SIZE);
    const auto u2 = double(current_u + width) / double(TEX_SIZE);
    const auto v2 = double(current_v + height) / double(TEX_SIZE);

    g.mesh = sushi::load_static_mesh_data(
        {{left, bottom, 0.f}, {left, top, 0.f}, {right, top, 0.f}, {right, bottom, 0.f}},
        {{0.f, 0.f, 1.f}, {0.f, 0.f, 1.f}, {0.f, 0.f, 1.f}, {0.f, 0.f, 1.f}},
        {{u, v}, {u, v2}, {u2, v2}, {u2, v}},
        {{{{0, 0, 0}, {1, 1, 1}, {2, 2, 2}}}, {{{2, 2, 2}, {3, 3, 3}, {0, 0, 0}}}});

    g.advance = advance;
    g.width = width;
    g.height = height;

    advance_v = std::max(advance_v, height);
    current_u += width;

    glyphs[unicode] = std::move(g);

    return true;
}
