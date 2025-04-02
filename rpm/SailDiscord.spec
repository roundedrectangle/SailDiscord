%define package_library "no"
# See README

Name:       harbour-saildiscord

Summary:    An unofficial Discord client for SailfishOS
Version:    0.8.4
Release:    1
License:    LICENSE
URL:        http://example.org/
Source0:    %{name}-%{version}.tar.bz2
Requires:   sailfishsilica-qt5 >= 0.10.9
#Requires:   sailfish-components-webview-qt5
Requires:   pyotherside-qml-plugin-python3-qt5
BuildRequires:  pkgconfig(sailfishapp) >= 1.0.3
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  desktop-file-utils
#BuildRequires:  pkgconfig(qt5embedwidget)

%if %{package_library} == "yes"
BuildRequires:  python3-base
BuildRequires:  python3-devel
BuildRequires: python3-pip
#BuildRequires: libjpeg-turbo
#BuildRequires: libjpeg-turbo-devel
BuildRequires: git
Requires: python3dist(pillow)
%endif

%if %{package_library} == "no"
Requires:  python3-base
Requires: gcc
Requires: python3-devel
Requires: python3-pip
%endif

%define __provides_exclude_from ^%{_datadir}/.*$
%global _missing_build_ids_terminate_build 0
%define __requires_exclude ^libXau|libbrotlicommo|libfreetype|libjpeg|liblzma|libsharpyuv|libwebp|python3dist(attrs)|python3dist(idna)|python3dist(pyopenssl).*$

%description
Discord in your pocket


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
python3 -m pip install --upgrade "git+https://github.com/dolfies/discord.py-self" "requests" --target=%_builddir/deps
rm -rf %_builddir/deps/bin
strip -s %_builddir/deps/charset_normalizer/*.so || echo
strip -s %_builddir/deps/google/_upb/*.so || echo
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
