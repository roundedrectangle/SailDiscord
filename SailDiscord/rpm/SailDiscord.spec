%define package_library "yes"
# See README

Name:       SailDiscord

Summary:    An unofficial Discord client for SailfishOS
Version:    0.1
Release:    1
License:    LICENSE
URL:        http://example.org/
Source0:    %{name}-%{version}.tar.bz2
Requires:   sailfishsilica-qt5 >= 0.10.9
Requires:   qtmozembed-qt5
Requires:   sailfish-components-webview-qt5
#Requires:   sailfish-components-webview-qt5-devel
Requires:   sailfish-components-webview-qt5-pickers
#Requires:   sailfish-components-webview-qt5-examples
Requires:   sailfish-components-webview-qt5-popups
Requires:   pyotherside-qml-plugin-python3-qt5
BuildRequires:  pkgconfig(sailfishapp) >= 1.0.3
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  desktop-file-utils
BuildRequires:  pkgconfig(qt5embedwidget)

%if %{package_library} == "yes"
BuildRequires:  python3-base
BuildRequires: python3-devel
#BuildRequires: python3-pip # doesn't work for now; no fix yet
%endif

%if %{package_library} == "no"
Requires:  python3-base
Requires: gcc
Requires: python3-devel
Requires: python3-pip
%endif

%description
Short description of my Sailfish OS Application


%prep
%setup -q -n %{name}-%{version}

%build

%qmake5 

%make_build

# >> build post

%if %{package_library} == "yes"
#python3 -m ensurepip --default-pip # a workaround for BuildRequires: python3-pip; a better solution for now is building sailfish-rpn-calc
python3 -m pip install "discord.py-self>=2.0" --target=%_builddir/deps
#python3 -m pip install "discord.py-self>=2.0" "protobuf==5.27.0" --target=%_builddir/deps
rm -rf %_builddir/deps/google/_upb
%endif

# << build post

%install

%qmake5_install

# >> install post

%if %{package_library} == "yes"
cp -r deps %{buildroot}%{_datadir}/%{name}/qml/pages/deps
%endif

# << install post


desktop-file-install --delete-original         --dir %{buildroot}%{_datadir}/applications                %{buildroot}%{_datadir}/applications/*.desktop

%files
%defattr(-,root,root,-)
%{_bindir}/%{name}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
