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
Requires:   sailfish-components-webview-qt5-devel
Requires:   sailfish-components-webview-qt5-pickers
Requires:   sailfish-components-webview-qt5-examples
Requires:   sailfish-components-webview-qt5-popups
Requires:   pyotherside-qml-plugin-python3-qt5
BuildRequires:  pkgconfig(sailfishapp) >= 1.0.3
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  desktop-file-utils
BuildRequires:  pkgconfig(qt5embedwidget)
BuildRequires:  python3-base
BuildRequires: python3-devel
#BuildRequires: python3-pip # doesn't work for now; no fix yet

%description
Short description of my Sailfish OS Application


%prep
%setup -q -n %{name}-%{version}

%build

%qmake5 

%make_build

# >> build post

#python3 -m ensurepip --default-pip # a workaround for BuildRequires: python3-pip; a better solution for now is building sailfish-rpn-calc
python3 -m pip install discord.py-self>=2.0 --target=%_builddir/deps

# << build post

%install

%qmake5_install

# >> install post

cp -r deps %{buildroot}%{_datadir}/%{name}/qml/pages/deps

# << install post


desktop-file-install --delete-original         --dir %{buildroot}%{_datadir}/applications                %{buildroot}%{_datadir}/applications/*.desktop

%files
%defattr(-,root,root,-)
%{_bindir}/%{name}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
