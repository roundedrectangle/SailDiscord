%define package_library "yes"
# See README

Name:       harbour-saildiscord

Summary:    An unofficial Discord client for SailfishOS
Version:    0.10.3
Release:    1
License:    LICENSE
URL:        http://example.org/
Source0:    %{name}-%{version}.tar.bz2
Requires:   sailfishsilica-qt5 >= 0.10.9
#Requires:   sailfish-components-webview-qt5
Requires:  python3-base >= 3.11
Requires:   pyotherside-qml-plugin-python3-qt5
BuildRequires:  pkgconfig(sailfishapp) >= 1.0.3
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  desktop-file-utils
#BuildRequires:  pkgconfig(qt5embedwidget)

%if %{package_library} == "yes"
BuildRequires:  python3-base >= 3.11
BuildRequires:  python3-devel
BuildRequires: python3-pip
#BuildRequires: libjpeg-turbo
#BuildRequires: libjpeg-turbo-devel
BuildRequires: git
%else
Requires: gcc
Requires: python3-devel
Requires: python3-pip
%endif

%define __provides_exclude_from ^%{_datadir}/.*$
%global _missing_build_ids_terminate_build 0
%define __requires_exclude ^libXau|libbrotlicommo|libfreetype|libjpeg|liblzma|libsharpyuv|libwebp|python3dist(attrs)|python3dist(idna)|python3dist(pyopenssl)|libffi.*$

%description
Discord in your pocket


%prep
%setup -q -n %{name}-%{version}

%build

%qmake5 \
    VERSION=%{version} \
    RELEASE=%{release}

%make_build

#zypper install git

%if %{package_library} == "yes"
##python3 -m pip install --upgrade pip
##python3 -m pip cache purge
python3 -m pip install --no-cache-dir --force-reinstall --upgrade https://github.com/roundedrectangle/pyotherside-utils/releases/download/latest/pyotherside_utils-1.0-py3-none-any.whl --target=%_builddir/deps
##python3 -m pip install "git+https://github.com/dolfies/discord.py-self@e31a4e6fcfdad45ce30d99bb9b6e1d902ab8ea7c" --target=%_builddir/deps
python3 -m pip install discord.py-self==2.1.0 --target=%_builddir/deps
rm -rf %_builddir/deps/bin
strip -s %_builddir/deps/charset_normalizer/*.so || echo
strip -s %_builddir/deps/google/_upb/*.so || echo
%endif

%install

%qmake5_install

%if %{package_library} == "yes"
mkdir -p %{buildroot}%{_datadir}/%{name}/lib/
cp -r deps %{buildroot}%{_datadir}/%{name}/lib/deps
%endif


desktop-file-install --delete-original         --dir %{buildroot}%{_datadir}/applications                %{buildroot}%{_datadir}/applications/*.desktop

%files
%defattr(-,root,root,-)
%{_bindir}/%{name}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
