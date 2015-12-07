# SparkleFormation Parameters Callback

Provides automatic assignment of stack parameter information.
Currently supported workflows:

* Infrastructure Mode

## Usage

### Infrastructure Mode

Infrastructure mode assumes a single template which describes
an entire infrastructure (generally via nested templates). A
configuration file can provide all information required for the
root stack, as well as all descendant stacks.

#### Enable

The `sfn-parameters` callback is configured via the `.sfn`
configuration file. First the callback must be enabled:

~~~ruby
Configuration.new do
  callbacks do
    require ['sfn-parameters']
    default ['parameters_infrastructure']
  end
end
~~~

#### Configure

Some optional configuration is available via the `.sfn` file
to control the behavior of the callback:

~~~ruby
Configuration.new do
  sfn_parameters do
    directory 'infrastructure'
    destination 'default'
  end
end
~~~

* `directory` - Relative path from repository root to directory containing configuration files
* `destination` - Name of file holding configuration minus the extension

#### Functionality

One file will contain the configuration information required
for the stack operation (create/update). The location of this
file is generated using the configuration values provided
above. Using the default values used in the example above, the
file will be expected at:

~~~
REPO_ROOT/infrastructure/default.{rb,xml,json,yaml,yml}
~~~

The contents of the file will be processed using the bogo-config
library. This allows defining the file in a serialization format
(JSON, YAML, XML) or as a Ruby file.

#### File format

The basic structure of the file in JSON:

~~~json
{
  "parameters": {},
  "compile_parameters": {},
  "apply_stacks": [],
  "stacks": {}
}
~~~

Break down of the keys:

* `parameters` - Run time parameters sent to the orchestration API
* `compile_parameters` - Compile time parameters used to generate the template
* `apply_stacks` - List of stacks whose outputs should be applied
* `stacks`- Nested stack information

##### Example

~~~json
{
  "parameters": {
    "stack_creator": "chris"
  },
  "apply_stacks": [
    "networking"
  ],
  "stacks": {
    "compute_stack": {
      "parameters": {
        "ssh_key": "default"
      }
    }
  }
}
~~~

# Info

* Repository: https://github.com/sparkleformation/sfn-parameters
* IRC: Freenode @ #sparkleformation
