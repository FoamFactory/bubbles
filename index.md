# Bubbles

A gem for easily defining client REST interfaces in ruby

> If you're using Rails, it's suggested to have a `config/initializers/bubbles.rb` configuration file where you can easily configure your endpoints and environments. If you're not using Rails, then you can put this configuration just about anywhere, provided it's executed before where you want to use it.

## Quickstart
In `config/initializers/bubbles.rb`, add the following:
```ruby
require 'bubbles'

Bubbles.configure do |config|
  config.endpoints = [
    {
      :method => :get,
      :location => :version,
      :authenticated => false,
      :api_key_required => false
    }
  ]

  config.environment = {
    :scheme => 'http',
    :host => '0.0.0.0',
    :port => '1234'
  }
end
```

The `config.endpoints` section is where you configure which endpoints you want to support. The `config.environment` defines an environment, or remote configuration, for accessing the endpoint on a specific remote destination.

Now, you can use this endpoint with:
```ruby
require 'bubbles'
...

def version
  resources = Bubbles::Resources.new

  # The following will make a GET request to
  # http://0.0.0.0:1234/version and return the result.
  result = resources.environment.version

  puts(result)
end
```

## Detailed Documentation
There are currently two parts to a bubbles configuration: the _environments_ and the _endpoints_. Bubbles is configured in a _bubbles configuration block_:
```ruby
Bubbles.configure do |config|
  # You can add configuration for Bubbles here using config.endpoints and config.environment
end
```

This configuration block can be run at any time, but is typically set up in the initializer section of an app's startup. If desired, configuration can happen separately. That is, you can initialize environments within your initializer file and then initialize endpoints within another section of the application. Just note that when endpoints are defined, it overwrites _all_ endpoints of a configuration, not just the ones you choose to change.

### Environments
> :construction: Environment names used to be hardcoded into Bubbles. You can now access the current environment using `Bubbles::Resources.new.environment`. This section is left in the documentation for future reference, as we will eventually be adding back named environments (see FoamFactory/bubbles#23 for tracking information).

Three environments are currently available to be set up within bubbles. These are:
  - `local_environment` : Designed to be used for a local API for development testing.
  - `staging_environment` : Designed to be used for a remote API for second-stage testing or production-like deployment.
  - `production_environment` : Designed to be used for a production environment.

While the names are hardcoded, the environments can be used for anything - you could easily use a `local_environment` to store the information for one of your production servers.

#### Configuration of Environments
Environments are configured as part of the _bubbles configuration block_ and can have the following parameters:

  - `scheme`: The scheme for accessing endpoints on this host. Should be one of `http` or `https`. Defaults to `http`.
  - `host`: A domain name or IP address for the remote host to access for the environment.  Defaults to `127.0.0.1`.
  - `port`: The port to use to access the remote host. Defaults to `1234`.
  - `api_key`: The API key to send along with requests for a given environment, if an API key is required. This is optional, and defaults to `nil`.
  - `headers`: A `Hash` of key-value pairs that contain additional headers to pass to every call to this endpoint. Defaults to `{}`.

You can configure all three environments at once in the _bubbles configuration block_:
```ruby
Bubbles.configure do |config|
  config.environment = {
    :scheme => 'http',
    :host => '0.0.0.0',
    :port => '1234'
  }

  # Note: This is deprecated for the time being. See (FoamFactory/bubbles/#23).
  # config.staging_environment = {
  #   :scheme => 'http',
  #   :host => 'stage.api.foamfactory.com',
  #   :port => '80'
  # }

  # Note: This is deprecated for the time being. See (FoamFactory/bubbles/#23).
  # config.production_environment = {
  #   :scheme => 'https',
  #   :host => 'api.foamfactory.com',
  #   :port => '443'
  # }
end
```

If you choose a scheme of `http` and leave off the `port` configuration variable, it will default to `80`. Similarly, `https` will default to a port of `443`.

#### Configuration of Endpoints
Endpoints are the meat and potatoes of REST interaction. By indicating a _method_, _uri_, _body_, and _headers_, you are effectively making a function call on a remote server.

_Endpoints_ are specified as an array of objects within the _bubbles configuration block_:

```ruby
config.endpoints = [
  # Individual endpoint definitions go here
]
```

When processing each of these endpoint definitions, a method is created on instances of `RestEnvironment` that allows you to call the method in question. For example, an endpoint defined as:
```ruby
{
  :method => :get,
  :location => :version,
  :authenticated => false,
  :api_key_required => false
}
```

will create a method on instances of `RestEnvironment` called `version`, which will execute the appropriate REST call (via `RestClient`) and return a `RestClient::Response` object.

Each _endpoint_ object can have the following attributes:

| Name    | Description         | Required? | Default |
| :---    | :------------------ | :-------: | :-----: |
| `method`| The HTTP method to use to access the API for this endpoint. Must be one of `GET`, `POST`, `PUT`, `PATCH`, `DELETE`, or `HEAD`. | Yes | N/A |
| `location`| The path to access the endpoint. This is placed after the `host:port` section to build the URI. It may have URI parameters in the form of `{paramName}`. If a URI parameter is specified within the `location`, a `uri_params` hash will be expected to be passed to the calling method to replace the placeholder values. | Yes | N/A |
| `name` | The name to give the method created to make this REST call. | No | The value of the `location` parameter, with slashes (`/`) replaced with underscores (`_`). |
| `authorization` | Whether or not this endpoint requires authentication prior to executing the call. If true, then an `authorization_token` will be added to the method as a parameter to be passed when the method is called. This parameter will be placed in an `Authorization` header when the REST call is executed. | No | `false` |
| `api_key_required` | Whether or not an API key is required. If `true`, a parameter will be added to the method created to execute the REST API call named `api_key`. The value of this parameter will be set as the value of the `X-Api-Key` header when making the REST API call. | No | `false` |
| `return_type` | Must be one of: `[full_response, body_as_object, body_as_string]`. This specifies what type of response is expected from the `Endpoint`. A value of `full_response` will return the full `RestClient::Response` object to the client. A value of `body_as_string` will return the `RestClient::Response.body` value as a `String`. A value of `body_as_object` will take the `RestClient::Response.body` parameter and parse it as an `OpenStruct` object, and return the result of this parsing operation. | No | `body_as_string` |
| `encode_authorization` | Whether the `data` passed as part of the request should be re-encoded as an `Authorization: Basic` header (and Base64 encoded). Typically, this is only used for initial username/password authentication. | No | `false` |
| `headers` | A `Hash` of key-value pairs specifying additional headers (the `key` specifies the name of the header, and the `value` specifies the value) that should be passed with each call to this `Endpoint`. Defaults to `{}`.

### Examples
These examples are taken almost directly from our [test suite](https://github.com/FoamFactory/bubbles/blob/master/spec/bubbles/resources_spec.rb). For more detailed examples, please refer to our specifications located in the `/spec` directory.

#### GET the version of the software (unauthenticated, no API key required)
**Configuration**:

```ruby
require 'bubbles'

Bubbles.configure do |config|
  config.endpoints = [
    {
      :method => :get,
      :location => :version,
      :authenticated => false,
      :api_key_required => false,
      :return_type => :body_as_object
    }
  ]

  config.environment = {
    :scheme => 'http',
    :host => '0.0.0.0',
    :port => '1234'
  }
end
```

**Usage**:
```ruby
it 'should return an object containing the version information from the API' do
  resources = Bubbles::Resources.new
  environment = resources.environment

  response = environment.version
  expect(response).to_not be_nil
  expect(response.name).to eq('My Sweet API')
  expect(response.versionName).to eq('0.0.1')
end
```

#### GET a specific user by id (authentication required)
**Configuration**:
```ruby
Bubbles.configure do |config|
  config.endpoints = [
    {
      :method => :get,
      :location => 'users/{id}',
      :authenticated => true,
      :name => :get_user,
      :return_type => :body_as_object
    }
  ]

  config.environment = {
    :scheme => 'http',
    :host => '127.0.0.1',
    :port => '9002'
  }
end
```

**Usage**:
```ruby
it 'should return an object containing a user with id = 4' do
  environment = Bubbles::Resources.new.environment
  user = environment.get_user(@auth_token, {:id => 4})
  expect(user).to_not be_nil

  expect(user.id).to eq(4)
end
```

#### POST a login (i.e. retrieve an authorization token)
**Configuration**:
```ruby
Bubbles.configure do |config|
  config.endpoints = [
    {
      :method => :post,
      :location => :login,
      :authenticated => false,
      :api_key_required => true,
      :encode_authorization => [:username, :password],
      :return_type => :body_as_object
    }
  ]

  config.environment = {
    :scheme => 'http',
    :host => '127.0.0.1',
    :port => '9002',
    :api_key => 'someapikey'
  }
end
```

**Usage**:
```ruby
it 'should return a user data structure with a valid authorization token' do
  environment = Bubbles::Resources.new.environment

  data = { :username => 'myusername', :password => 'mypassword' }
  login_object = environment.login data

  auth_token = login_object.auth_token

  expect(auth_token).to_not be_nil
end
```

#### DELETE a user by id
**Configuration**:
```ruby
Bubbles.configure do |config|
  config.endpoints = [
    {
      :method => :delete,
      :location => 'users/{id}',
      :authenticated => true,
      :name => 'delete_user_by_id',
      :return_type => :body_as_object
    }
  ]

  config.environment = {
    :scheme => 'http',
    :host => '127.0.0.1',
    :port => '9002'
  }
```

**Usage**:
```ruby
it 'should successfully delete the given user' do
  environment = Bubbles::Resources.new.environment
  response = environment.delete_user_by_id @auth_token, {:id => 2}
  expect(response.success).to eq(true)
end
```

#### PATCH a user's information by providing a body containing information to update
**Configuration**:
```ruby
Bubbles.configure do |config|
  config.endpoints = [
    {
      :method => :patch,
      :location => 'users/{id}',
      :authenticated => true,
      :name => 'update_user',
      :return_type => :body_as_object
    }
  ]

  config.environment = {
    :scheme => 'http',
    :host => '127.0.0.1',
    :port => '9002'
  }
```

**Usage**:
```ruby
it 'should update information for the specified user' do
  environment = Bubbles::Resources.new.environment
  response = environment.update_user @auth_token, {:id => 4}, {:user => {:email => 'kleinhammer@somewhere.com' } }

  expect(response.id).to eq(4)
  expect(response.email).to eq('kleinhammer@somewhere.com')
end
```