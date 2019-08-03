# SparkleFormation Parameters Callback

Provides automatic assignment of stack parameter information.
Currently supported workflows:

* Infrastructure Mode
* Stacks Mode

This callback also supports optional encryption of stack
parameter files. Current implementations:

* OpenSSL

## Usage

Make the callback available by adding it to the bundle via the
project's Gemfile:

~~~ruby
group :sfn do
  gem 'sfn-parameters'
end
~~~

### Parameters

#### Enable

The `sfn-parameters` callback is configured via the `.sfn`
configuration file. First the callback must be enabled:

~~~ruby
Configuration.new do
  callbacks do
    require ['sfn-parameters']
    default ['parameters_infrastructure'] # or ['parameters_stacks']
  end
end
~~~

#### File format

The basic structure of the file in JSON:

~~~json
{
  "parameters": {},
  "compile_parameters": {},
  "apply_stacks": [],
  "mappings": {},
  "stacks": {},
  "template": "template_name",
  "options": {
    "tags": {
    }
  }
}
~~~

Break down of the keys:

* `parameters` - Run time parameters sent to the orchestration API
* `compile_parameters` - Compile time parameters used to generate the template
* `apply_stacks` - List of stacks whose outputs should be applied
* `mappings` - Hash of [STACK\_\_]old\_key new\_key to remap after apply\_stack
* `stacks`- Nested stack information
* `template` - Template name for this stack
* `options` - Extra options to set
 * `tags` - Set stack tags

#### Infrastructure Mode

Infrastructure mode assumes a single template which describes
an entire infrastructure (generally via nested templates). A
configuration file can provide all information required for the
root stack, as well as all descendant stacks.

##### Configure

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

##### Functionality

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

#### Stacks Mode

The stacks mode assumes multiple stacks represented by multiple templates. Each stack
will have a corresponding parameters file which matches the stack name.

##### Configure

Some optional configuration is available via the `.sfn` file
to control the behavior of the callback:

~~~ruby
Configuration.new do
  sfn_parameters do
    directory 'stacks'
  end
end
~~~

* `directory` - Relative path from repository root to directory containing configuration files

##### Functionality

One file will contain the configuration information required
for a single stack operation (create/update). The location of this
file is generated using the configuration value provided
above with the stack name. For example, if working with a stack
named `my-test-stack`, the file will be expected at:

~~~
REPO_ROOT/stacks/my-test-stack.{rb,xml,json,yaml,yml}
~~~

The contents of the file will be processed using the bogo-config
library. This allows defining the file in a serialization format
(JSON, YAML, XML) or as a Ruby file.

##### Example

~~~json
{
  "parameters": {
    "stack_creator": "chris"
  },
  "apply_stacks": [
    "networking"
  ]
}
~~~

### Encryption

This callback also supports encrypting stack parameter information for storage. The callback
adds a `parameters` command for handling encryption/decryption. Encryption is currently only
supported when using JSON format parameter files.

#### Configuration

Encryption configuration is controlled within the `.sfn` file:

~~~ruby
Configuration.new
  sfn_parameters do
    safe do
      key 'MY-SECRET-KEY'
      type 'ssl'
      cipher 'AES-256-CBC'
      iterations 10000
      salt 'sfn~parameters~crypt~salt'
    end
  end
end
~~~

##### Default options

* `type` - Safe type for encryption (default: ssl)

##### OpenSSL options

* `key` - **REQUIRED** - Secret shared key
* `cipher` - Cipher to be used (default: 'AES-256-CBC')
* `iterations` - Modify computation length (default: 10000)
* `salt` - Random string (default: random bytes)

#### Commands

##### Create a new file

Create a new parameters file and automatically lock it when complete:

~~~
$ sfn parameters create my-test-stack
~~~

##### Update an existing file

Edit the file and only lock the file if it was previously locked:

~~~
$ sfn parameters edit my-test-stack
~~~

##### Lock an existing file

~~~
$ sfn parameters lock my-test-stack
~~~

##### Unlock an existing file

~~~
$ sfn parameters unlock my-test-stack
~~~

##### Show existing values (as JSON)

~~~
$ sfn parameters show my-test-stack
~~~

_NOTE: Full paths can also be used when defining parameters file._

## Extending functionality (Resolvers)

Parameters can be fetched from remote locations using Resolvers. Resolvers
allow parameter values to be dynamically loaded via customized implementations.

### Resolver usage

Parameter values will be loaded via a resolver when the value of the
parameter is a hash which includes a `resolver` key. The `resolver` key
identifies the name of the resolver which should be loaded. For example:

~~~json
{
  "parameters": {
    "stack_creator": {
      "resolver": "my_resolver",
      "custom_key": "custom_value"
    }
  }
}
~~~

This will create an instance of the `MyResolver` class and will then
call the `MyResolver#resolve` with the value `{"custom_key" => "custom_value"}`.

If the value to resolve is not a complex value, the configuration can
be reduced to a single key/value pair where the key is the name of the
resolver, and the value is the value to be resolved. This would look like:

~~~json
{
  "parameters": {
    "stack_creator": {
      "my_resolver": "custom_value"
    }
  }
}
~~~

This will create an instance of the `MyResolver` class and will then
call the `MyResolver#resolve` with the value `"custom_value"`.

### Resolver implementation

New resolvers can be created by subclassing the `SfnParameters::Resolver`
class and implementing a `#resolve` method. An optional `#setup` method
is available for setting up the instance. This is called during instance
creation and has the entire sfn configuration available via the `#config`
method.

~~~ruby
require "sfn-parameters"

class MyResolver < SfnParameters::Resolver
  def setup
    # any custom setup
  end

  def resolve(value)
    if value["custom_key"] == "custom_value"
      "spox"
    else
      "unknown"
    end
  end
end
~~~

### Resolvers

List of known resolvers for sfn-parameters:

* AWS Simple Systems Manager - Parameter Store (https://github.com/novu/sfn-ssm)

# Info

* Repository: https://github.com/sparkleformation/sfn-parameters
* IRC: Freenode @ #sparkleformation
