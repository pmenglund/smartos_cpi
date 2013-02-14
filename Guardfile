guard :bundler, :notify => false do
  watch('Gemfile')
end

group :unit_tests do
  guard :rspec, :cli => "--color --format nested -p", :spec_paths => %w(spec/unit) do
    watch('spec/spec_helper.rb')            { 'spec/unit' }
    watch(%r{^spec/unit/.+_spec\.rb})
    watch(%r{^lib/smartos/cloud.rb})        { 'spec/unit' }
    watch(%r{^lib/smartos/cloud/(.+)\.rb})  { |m| "spec/unit/#{m[1]}_spec.rb" }
  end
end
