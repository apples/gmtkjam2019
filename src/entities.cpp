#include "entities.hpp"

#include "components.hpp"

#include <iostream>

void ember_database::on_destroy_entity(std::function<void(net_id id)> func) {
    destroy_entity_callback = std::move(func);
}

namespace scripting {

template <>
void register_type<ember_database>(sol::table& lua) {
    lua.new_usertype<ember_database::ent_id>("ent_id",
        sol::constructors<ember_database::ent_id(), ember_database::ent_id(const ember_database::ent_id&)>{},
        "get_index", &ember_database::ent_id::get_index);

    lua.new_usertype<ember_database>("ember_database",
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
