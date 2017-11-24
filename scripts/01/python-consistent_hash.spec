%define name python-consistent_hash
%define version 1.0
%define release 1
%define _relstr 0contrail

Summary: Implements consistent hashing with Python and the algorithm is the same as libketama.
Name:%{name}
Version: %{version}
Release: %{release}.%{_relstr}
Source0: https://pypi.python.org/packages/source/c/consistent_hash/consistent_hash-1.0.tar.gz
License: BSD License
Group: Development/Libraries
Prefix: %{_prefix}
Url: https://github.com/yummybian/consistent-hash

Provides: consistent_hash

%description
Implements consistent hashing that can be used when the number of server
nodes can increase or decrease.The algorithm that is used for consistent
hashing is the same as libketama <https://github.com/RJ/ketama>

%prep
%setup -n consistent_hash-%{version}

%build
env CFLAGS="$RPM_OPT_FLAGS" python setup.py build

%install
python setup.py install -O1 --root=$RPM_BUILD_ROOT --record=INSTALLED_FILES

%clean
rm -rf $RPM_BUILD_ROOT

%files -f INSTALLED_FILES
%defattr(-,root,root)
