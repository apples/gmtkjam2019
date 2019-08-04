#pragma once

#include "entities.hpp"
#include "json_serializers.hpp"

#include <Meta.h>
#include <glm/glm.hpp>
#include <sushi/texture.hpp>
#include <sushi/mesh.hpp>
#include <sol_forward.hpp>

#include <functional>
#include <string>
#include <type_traits>

#define REGISTER(NAME, ...)                                       \
    }                                                             \
    namespace meta {                                              \
    template <> constexpr auto registerName<component::NAME>() {  \
        return #NAME;                                             \
    }                                                             \
    template <> inline auto registerMembers<component::NAME>() {  \
        using comtype = component::NAME;                          \
        return members(__VA_ARGS__);                              \
    }                                                             \
    }                                                             \
    namespace component {
#define MEMBER(FIELD) member(#FIELD, &comtype::FIELD)

#define TAG(name) using name = ginseng::tag<struct name##_t>; REGISTER(name)

namespace component {

using json_serializers::basic::from_json;
using json_serializers::basic::to_json;

void register_all_components(sol::table& table);

struct net_id {
    ember_database::net_id id;
};

REGISTER(net_id,
         MEMBER(id))

struct position {
    int layer = 0;
    glm::vec2 pos = {0, 0};
};

REGISTER(position,
         MEMBER(layer),
         MEMBER(pos))

struct velocity {
    glm::vec2 vel = {0, 0};
};

REGISTER(velocity,
         MEMBER(vel))

struct script {
    std::string name;
    int next_tick;
};

REGISTER(script,
         MEMBER(name),
         MEMBER(next_tick))

struct sprite {
    int r;
    int c;
};

REGISTER(sprite,
         MEMBER(r),
         MEMBER(c))

struct controller {
    sol::table data;
};

REGISTER(controller,
         MEMBER(data))

struct body {
    float width = 1;
    float height = 1;

    bool dynamic = true;
    bool solid = true;

    bool edge_left = true;
    bool edge_right = true;
    bool edge_bottom = true;
    bool edge_top = true;
};

REGISTER(body,
         MEMBER(width),
         MEMBER(height),
         MEMBER(dynamic),
         MEMBER(solid),
         MEMBER(edge_left),
         MEMBER(edge_right),
         MEMBER(edge_bottom),
         MEMBER(edge_top))

} //namespace component

#undef TAG
#undef MEMBER
#undef REGISTER
