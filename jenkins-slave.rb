# Rubydoc: https://rubydoc.brew.sh/Formula.html
class JenkinsSlave < Formula
  desc "Jenkins Slave for macOS"
  homepage "https://jenkins.io/projects/remoting/"
  url "https://repo.jenkins-ci.org/releases/org/jenkins-ci/main/remoting/4.5/remoting-4.5.jar"
  sha256 "509fdd80048747c9e2e0ba90317e0845e6a95acd0d65995e7af72d57ee924267"

  bottle :unneeded

  depends_on "openjdk@11"

  def configure_script_name
    "#{name}-configure"
  end

  def log_file
    "#{var}/log/#{name}.log"
  end

  def install
    libexec.install "remoting-#{version}.jar"
    bin.write_jar_script libexec / "remoting-#{version}.jar", name
    (bin + configure_script_name).write configure_script
  end

  def caveats
    <<~STRING
      WARNING:
        You must configure the daemon first:

      Step 1: Run theconfigure script

        #{configure_script_name} --url "https://my-jenkins.com/computer/agentname/slave-agent.jnlp" \
          --secret "bd38130d1412b54287a00a3750bd100c"

        This is an example. You must change url and secret according to your Jenkins setup.
        For more information about the configuration script run: #{configure_script_name} --help

      Step 2: Start the Jenkins Slave via brew services

        If you want to start on machine boot:

        sudo brew services start #{name}

        If you want to start on login, just do this:

        brew services start #{name}

      Step 3: Verify daemon is running

        sudo launchctl list | grep #{plist_name}

        Logs can be inspected here: #{log_file}
    STRING
  end

  def configure_script
    <<~STRING
      #!/bin/bash

      set -eu

      PLIST_FILE='#{prefix}/#{plist_name}.plist'
      JENKINS_URL=""
      JENKINS_SECRET=""
      JENKINS_PATH="/usr/bin:/bin:/usr/sbin:/sbin"

      USAGE="Usage: $(basename "${0}") -u|--url <URL> -s|--secret <SECRET> [-p|--path <PATH>][-h|--help]"
      HELP=$(cat <<- EOT
      This script configures the launchctl configuration for the jenkins-slave service.

      Options:

        -u|--url <URL>          Required URL to the JNLP endpoint of the Jenkins slave.
        -s|--secret <SECRET>    Required secret for the slave node to authenticate against the master.
        -p|--path <PATH>        Optional path to set. Defaults to '/usr/bin:/bin:/usr/sbin:/sbin'.
        -h|--help               Show this help.

      Example:

        jenkins-slave-configure --url http://your-jenkins/computer/node/slave-agent.jnlp --secret ******

        jenkins-slave-configure --url http://your-jenkins/computer/node/slave-agent.jnlp --secret ****** \
          --path '/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin'
      EOT
      )

      print_help() {
        echo "${USAGE}"
        echo
        echo "${HELP}"
        echo
      }

      echo_err() {
        echo "${1}" >&2
      }

      error() {
        echo_err "Error: ${1}"
      }

      while (( "$#" )); do
        case "${1}" in
          -u|--url)
          if [ -n "${2}" ] && [ "${2:0:1}" != "-" ]; then
              JENKINS_URL="${2}"
              shift 2
          else
              error "Argument for ${1} is missing"
              echo_err "${USAGE}"
              exit 1
          fi
          ;;
        -s|--secret)
          if [ -n "${2}" ] && [ "${2:0:1}" != "-" ]; then
              JENKINS_SECRET="${2}"
              shift 2
          else
              error "Argument for ${1} is missing"
              echo_err "${USAGE}"
              exit 1
          fi
          ;;
        -p|--path)
          if [ -n "${2}" ] && [ "${2:0:1}" != "-" ]; then
              JENKINS_PATH="${2}"
              shift 2
          else
              error "Argument for ${1} is missing"
              echo_err "${USAGE}"
              exit 1
          fi
          ;;
        -h|--help)
          print_help
          exit 0
          ;;
        *)
          error "Unsupported argument: $1!"
          echo_err "${USAGE}"
          ;;
        esac
      done

      if [[ "${JENKINS_URL}" == "" ]]; then
        error "Required argument --url not given!"
        echo_err "${USAGE}"
        exit 2
      fi

      if [[ "${JENKINS_SECRET}" == "" ]]; then
        error "Required argument --secret not given!"
        echo_err "${USAGE}"
        exit 2
      fi

      sed -i '' "s|REPLACE_PATH|${JENKINS_PATH}|g" "${PLIST_FILE}"
      sed -i '' "s|REPLACE_URL|${JENKINS_URL}|g" "${PLIST_FILE}"
      sed -i '' "s|REPLACE_SECRET|${JENKINS_SECRET}|g" "${PLIST_FILE}"
    STRING
  end

  def plist_name
    "org.jenkins-ci.#{name}"
  end

  def plist
    <<~STRING
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
        <dict>
          <key>Label</key>
          <string>#{plist_name}</string>

          <key>UserName</key>
          <string>#{ENV['USER']}</string>

          <key>EnvironmentVariables</key>
          <dict>
            <key>PATH</key>
            <string>REPLACE_PATH</string>
          </dict>

          <key>ProgramArguments</key>
          <array>
            <string>#{bin}/#{name}</string>
            <string>-jnlpUrl</string>
            <string>REPLACE_URL</string>
            <string>-secret</string>
            <string>REPLACE_SECRET</string>
          </array>

          <key>RunAtLoad</key>
          <true/>

          <key>KeepAlive</key>
          <true/>

          <key>StandardErrorPath</key>
          <string>#{log_file}</string>

          <key>StandardOutPath</key>
          <string>#{log_file}</string>

          <key>SessionCreate</key>
          <true/>
        </dict>
      </plist>
    STRING
  end

  plist_options startup: true

  test do
    test_url = "http://example.com/jenkins"
    test_cmd = <<~STRING.gsub(/\s+/, " ").strip
      #{bin}/#{name} \
        -noReconnect \
        -jnlpUrl #{test_url} \
        -secret XXX
    STRING

    output = shell_output "#{test_cmd} 2>&1", 1
    assert_match /Failed to obtain #{test_url}\?encrypt=true/i, output
  end
end
