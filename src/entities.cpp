#include "entities.hpp"

#include "components.hpp"

#include <algorithm>
#include <iostream>

void ember_database::on_destroy_entity(std::function<void(net_id id)> func) {
    destroy_entity_callback = std::move(func);
}

void ember_database::add_to_layer(ent_id eid, int layer) {
    layers[layer].push_back(eid);

    if (has_component<component::layers>(eid)) {
        auto& com = get_component<component::layers>(eid);
        if (com.layer != 0) {
            std::clog << "ember_database::add_to_layer(): Entity already on another layer" << std::endl;
        }
        com.layer = layer;
    } else {
        add_component(eid, component::layers{layer});
    }
}

void ember_database::remove_from_layer(ent_id eid, int layer) {
    auto& ents = layers[layer];
    const auto iter = std::find(begin(ents), end(ents), eid);
    if (iter == end(ents)) {
        std::clog << "ember_database::remove_from_layer(): Entity not in layer" << std::endl;
        return;
    }
    std::swap(*iter, ents.back());
    ents.pop_back();

    auto &com = get_component<component::layers>(eid);
    com.layer = 0;
}

void ember_database::move_to_layer(ent_id eid, int layer) {
    auto oldlayer = get_layer_of(eid);
    remove_from_layer(eid, oldlayer);
    add_to_layer(eid, layer);
}

const std::vector<ember_database::ent_id>& ember_database::get_layer(int layer) {
    return layers[layer];
}

int ember_database::get_layer_of(ent_id eid) {
    if (has_component<component::layers>(eid)) {
        const auto& com = get_component<component::layers>(eid);
        return com.layer;
    } else {
        return 0;
    }
}

namespace scripting {

template <>
void register_type<ember_database>(sol::table& lua) {
    lua.new_usertype<ember_database::ent_id>("ent_id",
        sol::constructors<ember_database::ent_id(), ember_database::ent_id(const ember_database::ent_id&)>{},
        "get_index", &ember_database::ent_id::get_index);

    lua.new_usertype<ember_database>("ember_database",
        "add_to_layer", &ember_database::add_to_layer,
        "remove_from_layer", &ember_database::remove_from_layer,
        "move_to_layer", &ember_database::move_to_layer,
        "get_layer", &ember_database::get_layer,
        "get_layer_of", &ember_database::get_layer_of,
        "create_entity", &ember_database::create_entity,
        "destroy_entity", &ember_database::destroy_entity,
        "add_component", [](ember_database& db, ember_database::ent_id eid, sol::userdata com){
            return com["_add_component"](db, eid, com);
        },
        "remove_component", [](ember_database& db, ember_database::ent_id eid, sol::table com_type){
            return com_type["_remove_component"](db, eid);
        },
        "get_component", [](ember_database& db, ember_database::ent_id eid, sol::table com_type){
            return com_type["_get_component"](db, eid);
        },
        "has_component", [](ember_database& db, ember_database::ent_id eid, sol::table com_type){
            return com_type["_has_component"](db, eid);
        },
        "visit", [](ember_database& db, sol::protected_function func){
            db.visit([&func](ember_database::ent_id eid) {
                auto result = func(std::move(eid));
                if (!result.valid()) {
                    sol::error error = result;
                    throw std::runtime_error(std::string("ember_database.visit(): ") + error.what());
                }
            });
        });
}

} //namespace scripting
