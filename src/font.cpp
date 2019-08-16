#include "font.hpp"

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

const msdf_font::text_def& msdf_font::get_text(const std::string& str) const {
    if (!texts.count(str)) {
        struct data_t {
            std::vector<GLfloat> buffer;
            int num_tris;
        };

        std::unordered_map<int, data_t> tex2data;

        auto push_vertex = [&tex2data](int texture_index, glm::vec3 pos, glm::vec3 norm, glm::vec2 tex, glm::vec2 scale) {
            auto& data = tex2data[texture_index];
            data.buffer.push_back(pos.x);
            data.buffer.push_back(pos.y);
            data.buffer.push_back(pos.z);
            data.buffer.push_back(tex.x);
            data.buffer.push_back(tex.y);
            data.buffer.push_back(norm.x);
            data.buffer.push_back(norm.y);
            data.buffer.push_back(norm.z);
            data.buffer.push_back(scale.x);
            data.buffer.push_back(scale.y);
        };

        {
            float advance = 0;

            for (const auto& c : str) {
                auto codepoint = int(c); // not proper decoding :(

                auto* glyph = get_glyph(codepoint);

                if (!glyph) continue;

                push_vertex(
                    glyph->texture_index, {advance + glyph->pos[0].x, glyph->pos[0].y, 0.f}, {0.f, 0.f, 1.f}, glyph->uv[0], glyph->scale);
                push_vertex(
                    glyph->texture_index,
                    {advance + glyph->pos[0].x, glyph->pos[1].y, 0.f},
                    {0.f, 0.f, 1.f},
                    {glyph->uv[0].x, glyph->uv[1].y},
                    glyph->scale);
                push_vertex(
                    glyph->texture_index, {advance + glyph->pos[1].x, glyph->pos[1].y, 0.f}, {0.f, 0.f, 1.f}, glyph->uv[1], glyph->scale);
                push_vertex(
                    glyph->texture_index, {advance + glyph->pos[1].x, glyph->pos[1].y, 0.f}, {0.f, 0.f, 1.f}, glyph->uv[1], glyph->scale);
                push_vertex(
                    glyph->texture_index,
                    {advance + glyph->pos[1].x, glyph->pos[0].y, 0.f},
                    {0.f, 0.f, 1.f},
                    {glyph->uv[1].x, glyph->uv[0].y},
                    glyph->scale);
                push_vertex(
                    glyph->texture_index, {advance + glyph->pos[0].x, glyph->pos[0].y, 0.f}, {0.f, 0.f, 1.f}, glyph->uv[0], glyph->scale);

                tex2data[glyph->texture_index].num_tris += 2;
                advance += glyph->advance;
            }
        }

        auto text = text_def{};

        text.chunks.reserve(tex2data.size());

        for (const auto& [texture_index, data] : tex2data) {
            auto g = text_def_chunk{};

            g.texture_index = texture_index;
            g.mesh.vao = sushi::make_unique_vertex_array();
            g.mesh.vertex_buffer = sushi::make_unique_buffer();
            g.mesh.num_triangles = data.num_tris;
            g.mesh.bounding_sphere = 0;

            glBindBuffer(GL_ARRAY_BUFFER, g.mesh.vertex_buffer.get());
            glBufferData(GL_ARRAY_BUFFER, data.buffer.size() * sizeof(GLfloat), &data.buffer[0], GL_STATIC_DRAW);

            glBindVertexArray(g.mesh.vao.get());

            auto stride = sizeof(GLfloat) * (3 + 2 + 3 + 2);
            glEnableVertexAttribArray(sushi::attrib_location::POSITION);
            glEnableVertexAttribArray(sushi::attrib_location::TEXCOORD);
            glEnableVertexAttribArray(sushi::attrib_location::NORMAL);
            glEnableVertexAttribArray(3);
            glVertexAttribPointer(
                sushi::attrib_location::POSITION, 3, GL_FLOAT, GL_FALSE, stride,
                reinterpret_cast<const GLvoid *>(0));
            glVertexAttribPointer(
                sushi::attrib_location::TEXCOORD, 2, GL_FLOAT, GL_FALSE, stride,
                reinterpret_cast<const GLvoid *>(sizeof(GLfloat) * 3));
            glVertexAttribPointer(
                sushi::attrib_location::NORMAL, 3, GL_FLOAT, GL_FALSE, stride,
                reinterpret_cast<const GLvoid *>(sizeof(GLfloat) * (3 + 2)));
            glVertexAttribPointer(
                3, 2, GL_FLOAT, GL_FALSE, stride,
                reinterpret_cast<const GLvoid *>(sizeof(GLfloat) * (3 + 2 + 3)));

            glBindVertexArray(0);

            text.chunks.push_back(std::move(g));
        }

        texts[str] = std::move(text);
    }

    auto& ret = texts[str];

    ++ret.hits;

    return ret;
}

const sushi::texture_2d& msdf_font::get_texture(int i) const {
    return textures.at(i);
}

const msdf_font::glyph_def* msdf_font::get_glyph(int unicode) const {
    if (!glyphs.count(unicode)) {
        msdfgen::Shape shape;
        double advance;

        if (!msdfgen::loadGlyph(shape, font.get(), unicode, &advance)) {
            return nullptr;
        }

        shape.normalize();
        msdfgen::edgeColoringSimple(shape, 3.0);

        double left = 0, bottom = 0, right = 0, top = 0;
        shape.bounds(left, bottom, right, top);

        left -= 2;
        bottom -= 2;
        right += 2;
        top += 2;

        constexpr int scale = 1;

        auto width = int(right - left) * scale;
        auto height = int(top - bottom) * scale;

        msdfgen::Bitmap<msdfgen::FloatRGB> msdf(width, height);
        msdfgen::generateMSDF(msdf, shape, 4.0, scale, msdfgen::Vector2(-left, -bottom));

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
            current_v += advance_v + 1;
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

            const auto data = std::vector<GLubyte>(TEX_SIZE * TEX_SIZE * 4, 0);
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, TEX_SIZE, TEX_SIZE, 0, GL_RGBA, GL_UNSIGNED_BYTE, &data[0]);

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

        g.pos[0] = {left, bottom};
        g.pos[1] = {right, top};
        g.uv[0] = {u, v};
        g.uv[1] = {u2, v2};
        g.scale = float(TEX_SIZE) / glm::vec2{width, height};
        g.advance = advance;

        advance_v = std::max(advance_v, height);
        current_u += width + 1;

        glyphs[unicode] = std::move(g);
    }

    return &glyphs[unicode];
}

void msdf_font::clear_unused() const {
    for (auto iter = begin(texts); iter != end(texts);) {
        if (iter->second.hits == 0) {
            iter = texts.erase(iter);
        } else {
            iter->second.hits = 0;
            ++iter;
        }
    }
}
