#include "components.hpp"

#include "component_scripting.hpp"

namespace component {

void register_all_components(sol::table& table) {
    using scripting::register_type;

    register_type<net_id>(table);
    register_type<position>(table);
    register_type<velocity>(table);
    register_type<script>(table);
    register_type<sprite>(table);
    register_type<controller>(table);
    register_type<body>(table);
    register_type<warp>(table);
    register_type<checkpoint>(table);
    register_type<checkpoint_flag>(table);
    register_type<hurter>(table);
}

} //namespace component
