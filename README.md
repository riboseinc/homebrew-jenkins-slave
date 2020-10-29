# Homebrew for jenkins-slave

This tap contains a formula to install the Jenkins Slave on macOS.

## Install

```sh
brew tap iteratec/jenkins-slave
brew install jenkins-slave
```

You can start the slave manually for test via commandline:

```sh
jenkins-slave -jnlpUrl http://your-jenkins/computer/node/slave-agent.jnlp -secret 9...b
```

But this is not recomended for production setup and only for testing. For production setup you should install jenkins-slave as daemon. To do so you first need to configure he daemon:

```sh
jenkins-slave-configure --url http://your-jenkins/computer/node/slave-agent.jnlp --secret ******
```

and then install it:

```sh
sudo brew services start jenkins-slave
```

## Development

If you've cloned this repo and want to install your work in progress locally run the following command from inside this repository:

```sh
brew install --build-from-source ./jenkins-slave.rb
```

Good resource to stat is the [Formula Cookbook][cookbook].

## Launch Daemons

Services on Mac OS are done by [Launch Daemons][launch-daemons] ([Daemons and Services Programming Guide][launch-daemons-apple] from Apple).

To check if the service runs run this command:

```sh
sudo launchctl list | grep jenkins-slave
```

Thisshould print:

```sh
2673    0       org.jenkins-ci.remoting
```

The first number is the PID of the running command and the second number is the status code. A status indicates an error. You cna inspect it wuth `launchctl error <NUMBER>`.

## License

Code is under the [BSD 2 Clause license][license].

[cookbook]:             https://github.com/Homebrew/brew/blob/master/docs/Formula-Cookbook.md
[launch-daemons]:       http://www.launchd.info/
[launch-daemons-apple]: https://developer.apple.com/library/content/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html
[license]:              https://github.com/Homebrew/brew/tree/master/LICENSE.txt
