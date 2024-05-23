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
Requires:   pyotherside-qml-plugin-python3-qt5
BuildRequires:  pkgconfig(sailfishapp) >= 1.0.3
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  pkgconfig(qt5embedwidget)
BuildRequires:  desktop-file-utils
#BuildRequires:  python-pip
#BuildRequires: python3-devel >= 3.8

%description
Short description of my Sailfish OS Application


%prep
%setup -q -n %{name}-%{version}

%build

%qmake5 

%make_build

# >> build post

#cp -r %{_builddir}/../%{name}/pymodules ./
#cd pymodules/

#tar xvf discord.py-self-2.0.0.tar.gz
#cd discord.py-self-2.0.0
#python3 setup.py build
#cd ..

#cd ..

# << build post


%install

%qmake5_install

# >> install post

#cd pymodules/

#cd discord.py-self-2.0.0
#echo %{buildroot}
#echo %{_datadir}/%{name}
#python3 setup.py install --root=%{buildroot} --prefix=%{_datadir}/%{name}/
#cd ..

#cd ..

python3 -m ensurepip --default-pip
python3 -m pip install discord.py-self>=2.0 --target=%{buildroot}%{_datadir}/%{name}/qml/pages/deps

# << install post


desktop-file-install --delete-original         --dir %{buildroot}%{_datadir}/applications                %{buildroot}%{_datadir}/applications/*.desktop

%files
%defattr(-,root,root,-)
%{_bindir}/%{name}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
