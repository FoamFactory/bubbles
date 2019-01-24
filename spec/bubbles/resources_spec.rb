require 'bubbles'
require 'spec_helper'

describe Bubbles::Resources do
  describe 'Endpoint' do
    context 'accessed with a GET request' do
      before do
        Bubbles.configure do |config|
          config.endpoints = [
            {
              :method => :get,
              :location => :version,
              :authenticated => false,
              :api_key_required => false,
              :expect_json => true
            },
            {
              :method => :get,
              :location => :students,
              :authenticated => true,
              :api_key_required => false,
              :name => :list_students,
              :expect_json => true
            }
          ]

          config.local_environment = {
            :scheme => 'http',
            :host => '127.0.0.1',
            :port => '1234'
          }

          config.staging_environment = {
            :scheme => 'http',
            :host => '127.0.0.1',
            :port => '1234'
          }
        end
      end

      context 'that require no authentication' do
        context 'when using the local environment' do
          it 'should be able to retrieve a version from the API' do
            VCR.use_cassette('get_version_unauthenticated') do
              resources = Bubbles::Resources.new
              local_env = resources.local_environment

              response = local_env.version
              expect(response).to_not be_nil
              expect(response.name).to eq('Sinking Moon API')
              expect(response.versionName).to eq('2.0.0')

              deploy_date = Date.parse(response.deployDate)
              expect(deploy_date.year).to eq(2018)
              expect(deploy_date.month).to eq(1)
              expect(deploy_date.day).to eq(2)
            end
          end
        end
      end

      context 'that require an authorization token' do
        context 'when using the staging environment' do
          it 'should be able to list students from the staging environment' do
            VCR.use_cassette('get_students_authenticated') do
              auth_token = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJjcmVhdGlvbl9kYXRlIjoiMjAxNy0xMC0xNVQxMToyNjozMS0wNTowMCIsImV4cGlyYXRpb25fZGF0ZSI6IjIwMTctMTEtMTRUMTE6MjY6MzEtMDU6MDAiLCJ1c2VyX2lkIjoxfQ.dyCWwE4wk7aTfjnGncsqp_jq5QyICKYQPkBh5nLQwFU'
              resources = Bubbles::Resources.new
              local_env = resources.local_environment

              response = local_env.list_students(auth_token)
              expect(response).to_not be_nil

              students = response.students
              expect(students.length).to eq(1)
              expect(students[0].name).to eq('Joe Blow')
              expect(students[0].zip).to eq('90263')
            end
          end
        end
      end
    end

    context 'accessed with a POST request' do
      before do
        Bubbles.configure do |config|
          config.endpoints = [
            {
              :method => :post,
              :location => :login,
              :authenticated => false,
              :api_key_required => true,
              :expect_json => true,
              :encode_authorization => [:username, :password]
            }
          ]

          config.local_environment = {
            :scheme => 'http',
            :host => '127.0.0.1',
            :port => '1234'
          }
        end
      end

      context 'when using the local environment' do
        context 'with a valid username and password' do
          it 'should successfully login' do
            VCR.use_cassette('login') do
              api_key = 'e4150c01953cd24ac18084b1cb0ddcb3766de03a'
              resources = Bubbles::Resources.new
              local_env = resources.local_environment


              login_object = local_env.login api_key, { :username => 'scottj', :password => '123qwe456' }
              # expect(response).to have_http_status(:ok)

              expect(login_object.id).to eq(1)
              expect(login_object.name).to eq('Scott Johnson')
              expect(login_object.username).to eq('scottj')
              expect(login_object.email).to eq('scottj@sinkingmoon.com')
              expect(login_object.auth_token).to_not be_nil
            end
          end
        end
      end
    end
  end
end