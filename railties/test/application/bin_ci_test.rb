# frozen_string_literal: true

require "isolation/abstract_unit"

module ApplicationTests
  class BinCiTest < ActiveSupport::TestCase
    include ActiveSupport::Testing::Isolation

    setup :build_app
    teardown :teardown_app

    def test_bin_ci_default_content
      Dir.chdir(app_path) do
        assert File.exist?("bin/ci"), "bin/ci does not exist"
        assert File.executable?("bin/ci"), "bin/ci is not executable"

        content = File.read("bin/ci")

        # Default steps
        assert_match(/bin\/rubocop/, content)
        assert_match(/bin\/brakeman/, content)
        assert_match(/hadolint/, content)
        assert_match(/bin\/rails test/, content)
        assert_match(/bin\/rails db:seed:replant/, content)

        # Node-specific steps excluded by default
        assert_no_match(/yarn audit/, content)

        # Bundle audit and GitHub signoff commented
        assert_match(/# .*gh signoff/, content)
      end
    end

    def test_bin_ci_without_rubocop_step
      app_dir = app_path("ci_test_without_rubocop")
      rails("new", app_dir, "--skip-rubocop")

      Dir.chdir(app_dir) do
        content = File.read("bin/ci")
        assert_not_match(/bin\/rubocop/, content)
      end
    end

    def test_bin_ci_without_brakeman_step
      app_dir = app_path("ci_test_without_brakeman")
      rails("new", app_dir, "--skip-brakeman")

      Dir.chdir(app_dir) do
        content = File.read("bin/ci")
        assert_not_match(/bin\/brakeman/, content)
      end
    end

    def test_bin_ci_without_dockerfile_step
      app_dir = app_path("ci_test_without_docker")
      rails("new", app_dir, "--skip-docker")

      Dir.chdir(app_dir) do
        content = File.read("bin/ci")
        assert_not_match(/hadolint/, content)
      end
    end

    def test_bin_ci_with_yarn_audit_step
      app_dir = app_path("ci_test_with_js")
      rails("new", app_dir, "--javascript=esbuild")

      Dir.chdir(app_dir) do
        content = File.read("bin/ci")
        assert_match(/yarn audit/, content)
      end
    end
  end
end
