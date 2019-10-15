function comparePermissionArrays(array1, array2) {
    return array1.sort().join(',') == array2.sort().join(',');
}

function toggleElement(list, element) {
    var existingElement = _.find(list, element);
    if (_.isUndefined(existingElement)) {
        return _.concat(list, element)
    }

    return _.without(list, existingElement);
}

window.InviteAdminForm = createReactClass({
    displayName: 'InviteAdminForm',

    getInitialState: function () {
        return {
            full_name: _.get(this.props, ['admin', 'full_name'], ''),
            email: _.get(this.props, ['email'], ''),
            role: _.get(this.props, ['admin', 'role'], ''),
            organization_id: _.get(this.props, ['admin', 'organization_id']),
            selected_permissions: _.get(this.props, ['selected_permissions'], []),
            selected_resources: _.get(this.props, ['selected_resources'], [])
        }
    },

    updateInput: function (key, value) {
        this.setState({[key]: value})
    },

    updateAccessLevel: function (access_level) {
        var new_permissions = _.chain(this.props.access_levels)
            .find(['name', access_level])
            .get('default_permissions')
            .map((slug) => _.find(this.props.permissions, ['slug', slug]))
            .value();

        this.setState({selected_permissions: new_permissions});
    },

    updatePermissions: function (permission) {
        var newPermissions = toggleElement(this.state.selected_permissions, permission);
        this.setState({selected_permissions: newPermissions});
    },

    updateResources: function (resources) {
        this.setState({selected_resources: _.uniq(resources)});
    },

    getPermissionsPayload: function () {
        return _.flatMap(this.state.selected_permissions, (permission) => {
            if (permission.resource_type == 'Organization') {
                return {
                    permission_slug: permission.slug,
                    resource_type: 'Organization',
                    resource_id: this.state.organization_id
                }
            } else if (permission.resource_type) {
                return _.chain(this.state.selected_resources)
                    .filter((resource) => resource.resource_type == permission.resource_type)
                    .map((resource) => {
                        return {
                            permission_slug: permission.slug,
                            resource_type: resource.resource_type,
                            resource_id: resource.resource_id
                        }
                    }).value();
            }
            return {permission_slug: permission.slug}
        });
    },

    submitForm: function () {
        var permissions_payload = this.getPermissionsPayload();
        var request_payload =
            _.chain(this.state)
                .pick(['full_name', 'email', 'role', 'mobile', 'location', 'organization_id'])
                .merge({permissions: permissions_payload})
                .value();

        $.ajax({
            type: this.props.submit_method,
            url: this.props.submit_route,
            contentType: "application/json",
            headers: {
                'X-CSRF-Token': document.querySelector("meta[name=csrf-token]").content
            },
            data: JSON.stringify(request_payload),
            success: () => {
                window.location.replace("/admins");
            }
        });
    },

    requiredResources: function () {
        return _.chain(this.state.selected_permissions)
            .map('resource_type')
            .uniq()
            .value();
    },

    access_level: function () {
        return _.chain(this.props.access_levels)
            .find((al) => comparePermissionArrays(_.map(this.state.selected_permissions, 'slug'), al.default_permissions))
            .get('name', 'custom')
            .value();
    },


    render: function () {
        return (
            <div>
                <TextInputField name="full_name" title="Full Name" value={this.state.full_name}
                                updateInput={this.updateInput.bind(this)}/>
                <TextInputField name="email" title="Email" value={this.state.email} updateInput={this.updateInput}/>
                <TextInputField name="role" title="Role" value={this.state.role} updateInput={this.updateInput}/>
                <CollectionRadioButtons name="organization_id" title="Organization"
                                        organizations={this.props.organizations}
                                        checked_id={this.state.organization_id}
                                        updateInput={this.updateInput}/>
                <AccessLevelComponent permissions={this.props.permissions}
                                      access_levels={this.props.access_levels}
                                      selected_level={this.access_level()}
                                      selected_permissions={this.state.selected_permissions}
                                      selected_resources={this.state.selected_resources}
                                      required_resources={this.requiredResources()}
                                      updateAccessLevel={this.updateAccessLevel}
                                      updatePermissions={this.updatePermissions}
                                      updateResources={this.updateResources}
                                      organization_id={this.state.organization_id}
                                      facility_groups={this.props.facility_groups}
                                      facilities={this.props.facilities}/>
                <button className="btn btn-primary" onClick={this.submitForm}>
                    {this.props.submit_text}
                </button>
            </div>
        );
    }
});