<table align="center" width="100%">
  <tr>
    <td>
      <strong><a href="#">Ricin</a></strong>: A Lightweight and Fully-Hackable Tox client powered by Vala & Gtk3!
    </td>
    <td>
      <img src="https://img.shields.io/badge/version-0.0.1-brightgreen.svg?style=flat">
    </td>
  </tr>
  <tr>
    <td align="center" width="100%" colspan="2">
      <big><b>Want to be involved? There are several ways you can help us! ^-^</b></big><br>
      <a href="#dependencies">Dependencies</a> -
      <a href="#compiling">Compiling</a> -
      <a href="#contribute">Contribute</a> -
      <a href="#support-ricin-developement">Support us</a> -
      <a href="#vala-resources-to-get-started">Get started with Vala</a>
    </td>
  </tr>
</table>

# Introduction
**Ricin** aims to be a _secure_, _lightweight_, _hackable_ and _fully-customizable_ chat client using **ToxCore** library. Ricin is a simple but powerful cross-platform client written in Vala and using Gtk+ 3.0.

_Screenshot might be outdated but it should give you a general idea of what Ricin is_
[Early version](https://camo.githubusercontent.com/0451a9e2ebf7994dc1d2f851b70728c14049bd16/68747470733a2f2f70726f78792e696e7374616e742d6861636b2e636f6d2f3f696d673d6148523063446f764c326b756157316e64584975593239744c7a464e656c427852566f756347356e)


# Dependencies
| Package name        | Version   |
|---------------------|-----------|
| [meson] \(building) | >=0.28.0  |
| [ninja] \(building) | >=1.5.1   |
| valac               | >=0.28.1  |
| gtk+3               | >=3.16    |
| [libtoxcore]        | >=0.0.0   |
| glib2               | >=2.38    |
| json-glib           | >=1.0     |
| libsoup             | >=2.4     |
| libnotify           | >=0.7.6   |

# Compiling

```bash
git clone --recursive https://github.com/RicinApp/Ricin.git
cd Ricin
mkdir build
meson . build
make debug
```

# Contribute
You can help improving Ricin by:

- [Proposing Pull-requests](https://github.com/RicinApp/Ricin/pulls)
- Reporting bugs
- Creating suggestions using the GitHub [issues tracker](https://github.com/RicinApp/Ricin/issues)

# Vala resources to get started
Before clicking on any link beside, you must know what is Vala and why it is so powerful and easy to use: [What is Vala?](https://wiki.gnome.org/Projects/Vala/About)

- [Official Vala website](https://live.gnome.org/Vala)
- [Official Vala documentation](http://www.valadoc.org)
- [Download Vala compiler and tools](https://wiki.gnome.org/Projects/Vala/Tools)
- [The Vala Tutorial](https://wiki.gnome.org/Projects/Vala/Tutorial): (English) (Spanish) (Russian) (Hebrew)
- [Vala for C# Programmers](https://wiki.gnome.org/Projects/Vala/ValaForCSharpProgrammers)
- [Vala for Java Programmers](https://wiki.gnome.org/Projects/Vala/ValaForJavaProgrammers): (English) (Russian)
- [Vala memory management explained](https://wiki.gnome.org/Projects/Vala/ReferenceHandling)
- [Writing VAPI files](https://wiki.gnome.org/Projects/Vala/LegacyBindings): A document that explains how to write VAPI binding files for a C library.

# Mockups

See
- https://github.com/gnome-design-team/gnome-mockups/tree/master/chat
- https://wiki.gnome.org/Design/Apps/Chat
- [misc/mockup2.png](misc/mockup2.png)

[libtoxcore]: https://github.com/irungentoo/toxcore/blob/master/INSTALL.md
[meson]: http://mesonbuild.com/
[ninja]: http://martine.github.io/ninja/
