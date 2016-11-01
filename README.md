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
  "stacks": {}
}
~~~

Break down of the keys:

* `parameters` - Run time parameters sent to the orchestration API
* `compile_parameters` - Compile time parameters used to generate the template
* `apply_stacks` - List of stacks whose outputs should be applied
* `mappings` - Hash of [STACK\_\_]old\_key new\_key to remap after apply\_stack
* `stacks`- Nested stack information

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
adds a `parameters` command for handling encryption/decryption.

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

_NOTE: Full paths can also be used when defining parameters file._

# Info

* Repository: https://github.com/sparkleformation/sfn-parameters
* IRC: Freenode @ #sparkleformation
