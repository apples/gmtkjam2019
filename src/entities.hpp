#pragma once

#include "scripting.hpp"
#include "json.hpp"
#include "utility.hpp"

#include <ginseng/ginseng.hpp>

#include <Meta.h>

#include <cstdint>
#include <unordered_map>
#include <optional>

class ember_database : public ginseng::database {
    template <typename... Coms>
    struct entity_serializer {
        static auto serialize(ember_database& db, ent_id eid) -> nlohmann::json {
            return nlohmann::json::object();
        }
    };

    template <typename Head, typename... Coms>
    struct entity_serializer<Head, Coms...> {
        static auto serialize(ember_database& db, ent_id eid) -> nlohmann::json {
            auto json = entity_serializer<Coms...>::serialize(db, eid);
            auto name = meta::getName<Head>();
            if (db.has_component<Head>(eid)) {
                json[name] = db.get_component<Head>(eid);
            } else {
                json[name] = nullptr;
            }
            return json;
        }
    };

public:
    using net_id = std::int64_t;

    void on_destroy_entity(std::function<void(net_id id)> func);

    template <typename... Coms>
    auto serialize_entity(ent_id eid) -> nlohmann::json {
        return entity_serializer<Coms...>::serialize(*this, eid);
    }

    void add_to_layer(ent_id eid, int layer);
    void remove_from_layer(ent_id eid, int layer);
    void move_to_layer(ent_id eid, int layer);
    const std::vector<ent_id>& get_layer(int layer);
    int get_layer_of(ent_id eid);

private:
    net_id next_id = 1;
    std::unordered_map<net_id, ent_id> netid_to_entid;
    std::function<void(net_id id)> destroy_entity_callback;
    std::unordered_map<int, std::vector<ent_id>> layers;
};

namespace scripting {

template <>
void register_type<ember_database>(sol::table& lua);

} //namespace scripting

namespace sol {

template <>
struct is_automagical<ember_database> : std::false_type {};

} //namespace sol
