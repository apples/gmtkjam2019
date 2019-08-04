#include "config.hpp"

#include "../utility.hpp"

namespace emberjs {

    nlohmann::json get_config() {
        auto config = ember_config_get();
        EMBER_DEFER { free(config); };
        return nlohmann::json::parse(config);
    }

} //namespace emberjs
