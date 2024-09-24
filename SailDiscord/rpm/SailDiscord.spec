%define package_library "no"
# See README

Name:       harbour-saildiscord

Summary:    An unofficial Discord client for SailfishOS
Version:    0.3.2
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
BuildRequires:  python3-devel
BuildRequires: python3-pip
BuildRequires: libjpeg-turbo
BuildRequires: libjpeg-turbo-devel
%endif

%if %{package_library} == "no"
Requires:  python3-base
Requires: gcc
Requires: python3-devel
Requires: python3-pip
%endif

# >> macros
%define __provides_exclude_from ^%{_datadir}/.*$
%global _missing_build_ids_terminate_build 0
# << macros


%description
Short description of my Sailfish OS Application


%prep
%setup -q -n %{name}-%{version}

%build

%qmake5 \
    VERSION=%{version} \
    RELEASE=%{release}

%make_build

# >> build post

#zypper install git

%if %{package_library} == "yes"
#python3 -m pip install --upgrade pip
#python3 -m pip cache purge
python3 -m pip install "discord.py-self>=2.0" "requests" "Pillow" --target=%_builddir/deps
#rm -rf %_builddir/deps/google/_upb
%endif

# << build post

%install

%qmake5_install

# >> install post

%if %{package_library} == "yes"
mkdir -p %{buildroot}%{_datadir}/%{name}/lib/
cp -r deps %{buildroot}%{_datadir}/%{name}/lib/deps
%endif

# << install post


desktop-file-install --delete-original         --dir %{buildroot}%{_datadir}/applications                %{buildroot}%{_datadir}/applications/*.desktop

%files
%defattr(-,root,root,-)
%{_bindir}/%{name}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
