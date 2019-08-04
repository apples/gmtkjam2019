local linq = require('linq')
local class = require('class')

local component_base = class()

local function assign(dest, source)
    for k,v in pairs(source) do
        dest[k] = v
    end
    return dest
end

local function is_event_name(str)
    return string.sub(str, 1, 3) == 'on_'
end

local function update_widget_properties(widget, prev_props, next_props)
    for k,v in pairs(prev_props) do
        if is_event_name(k) then
            widget[k] = nil
        else
            widget:set_attribute(k, nil)
        end
    end
    for k,v in pairs(next_props) do
        if is_event_name(k) then
            widget[k] = v
        else
            widget:set_attribute(k, type(v) == 'string' and v or tostring(v))
        end
    end
end

local function is_vdom_element(element)
    return type(element) == 'table' and
        element.type ~= nil and
        element.props ~= nil and
        element.children ~= nil
end

local function is_component_type(cls)
    if type(cls) ~= 'table' then return false end
    local mt = cls
    while mt ~= nil and mt ~= component_base do
        mt = getmetatable(mt).__index
    end
    return mt == component_base
end

local function is_component_instance(com)
    return type(com) == 'table' and
        is_component_type(getmetatable(com))
end

local function create_element(element_type, config, ...)
    assert(type(element_type) == 'string' or is_component_type(element_type))
    assert(type(config) == 'nil' or type(config) == 'table')

    local props = assign({}, config or {})

    local children = linq({...}, select('#', ...))
        -- Flatten children
        :reduce(
            linq({}),
            function (acc, child)
                if type(child) == 'table' and #child > 0 then
                    -- Flatten children that are arrays
                    return acc:concat(linq(child))
                elseif is_vdom_element(child) or type(child) == 'string' then
                    -- Leave single children alone
                    return acc:concat(linq({child}))
                else
                    -- Ignore nil/false
                    return acc
                end
            end)
        -- Convert text to elements
        :select(
            function (child)
                return type(child) == 'table' and
                    child or
                    create_element('_TEXT_ELEMENT_', { node_value = child })
            end)
        :tolist()

    for _,child in ipairs(children) do
        assert(is_vdom_element(child))
    end

    return {
        type = element_type,
        props = props,
        children = children,
    }
end

local function create_component_instance(element, instance)
    assert(is_vdom_element(element))
    assert(type(instance) == 'table')

    local element_type = element.type
    local props = element.props
    local children = element.children

    local component_instance = element_type.new(props, children)
    component_instance.internal_instance = instance

    return component_instance
end

local function instantiate(element, parent_widget)
    assert(is_vdom_element(element))

    local element_type = element.type
    local props = element.props
    local children = element.children

    if type(element_type) == 'string' then
        -- Instantiate widget element

        if element_type == '_TEXT_ELEMENT_' then
            error('_TEXT_ELEMENT_ not supported')
        end

        local widget = parent_widget:create_widget(element_type)

        update_widget_properties(widget, {}, props)

        local child_instances = linq(children)
        :select(function (c) return instantiate(c, widget) end)
            :tolist()

        local child_widgets = linq(child_instances)
            :select(function (child_instance) return child_instance.widget end)
            :tolist()

        for _,child_widget in ipairs(child_widgets) do
            widget:add_child(child_widget)
        end

        return {
            widget = widget,
            element = element,
            child_instances = child_instances
        }
    else
        local instance = {}
        local component_instance = create_component_instance(element, instance)
        local child_element = component_instance:render()
        local child_instance = instantiate(child_element, parent_widget)

        instance.widget = child_instance.widget
        instance.element = element
        instance.child_instance = child_instance
        instance.component_instance = component_instance

        return instance
    end
end

local function is_instance(instance)
    return type(instance) == 'table' and
        instance.widget ~= nil and
        is_vdom_element(instance.element)
end

local function is_widget_instance(instance)
    return is_instance(instance) and
        type(instance.child_instances) == 'table'
end

local function is_component_instance(instance)
    return is_instance(instance) and
        is_instance(instance.child_instance) and
        is_component_instance(instance.component_instance)
end

local reconcile -- forward

local function reconcile_children(instance, element)
    assert(is_widget_instance(instance))
    assert(is_vdom_element(element))

    local widget = instance.widget
    local child_instances = instance.child_instances
    local next_child_elements = element.children
    local new_child_instances = {}
    local count = math.max(#child_instances, #next_child_elements)

    for i = 1, count do
        local child_instance = child_instances[i]
        local child_element = next_child_elements[i]
        local new_child_instance = reconcile(widget, child_instance, child_element)

        if new_child_instance then
            new_child_instances[#new_child_instances + 1] = new_child_instance
        end
    end

    return new_child_instances
end

local function cleanup(instance)
    instance.widget = nil

    if instance.child_instance then
        cleanup(instance.child_instance)
    end

    if instance.child_instances then
        for _,v in ipairs(instance.child_instances) do
            cleanup(v)
        end
    end
end

reconcile = function (parent_widget, instance, element)
    assert(parent_widget ~= nil)
    assert(instance == nil or is_instance(instance))
    assert(element == nil or is_vdom_element(element))

    if instance == nil then
        -- Create instance

        local new_instance = instantiate(element, parent_widget)

        parent_widget:add_child(new_instance.widget)

        return new_instance
    elseif element == nil then
        -- Remove instance

        parent_widget:remove_child(instance.widget)
        cleanup(instance)

        return nil
    elseif instance.element.type ~= element.type then
        -- Replace instance

        local new_instance = instantiate(element, parent_widget)

        parent_widget:replace_child(instance.widget, new_instance.widget)
        cleanup(instance)

        return new_instance
    elseif type(element.type) == 'string' then
        -- Update instance

        update_widget_properties(instance.widget, instance.element.props, element.props)

        instance.child_instances = reconcile_children(instance, element)
        instance.element = element

        return instance
    else
        -- Update composite instance

        instance.component_instance.props = element.props

        local child_element = instance.component_instance:render()
        local old_child_instance = instance.child_instance
        local child_instance = reconcile(parent_widget, old_child_instance, child_element)

        instance.widget = child_instance.widget
        instance.child_instance = child_instance
        instance.element = element

        return instance
    end
end

local function render(element, container)
    assert(is_vdom_element(element))

    return reconcile(container, nil, element)
end

function component_base:constructor(props)
    self.props = props
    self.state = self.state or {}
end

function component_base:set_state(partial_state)
    assert(type(partial_state) == 'table')

    local new_state = {}
    assign(new_state, self.state)
    assign(new_state, partial_state)

    self.state = new_state

    local internal_instance = self.internal_instance
    local parent_widget = internal_instance.widget:get_parent()
    local element = internal_instance.element

    reconcile(parent_widget, internal_instance, element)
end

local function component()
    return class(component_base)
end

return {
    component = component,
    create_element = create_element,
    render = render
}
