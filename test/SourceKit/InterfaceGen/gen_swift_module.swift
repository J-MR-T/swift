import swift_mod_syn

func f(s : inout [Int]) {
  s.sort()
}

// RUN: %empty-directory(%t.mod)
// RUN: %empty-directory(%t.mod/mcp)
// RUN: %swift -emit-module -o %t.mod/swift_mod.swiftmodule %S/Inputs/swift_mod.swift -parse-as-library -disable-implicit-concurrency-module-import -disable-implicit-string-processing-module-import
// RUN: %sourcekitd-test -req=interface-gen -module swift_mod -- -Xfrontend -disable-implicit-concurrency-module-import -Xfrontend -disable-implicit-string-processing-module-import  -I %t.mod > %t.response
// RUN: %diff -u %s.response %t.response

// RUN: %sourcekitd-test -req=module-groups -module swift_mod -- -Xfrontend -disable-implicit-concurrency-module-import -Xfrontend -disable-implicit-string-processing-module-import  -I %t.mod | %FileCheck -check-prefix=GROUP-EMPTY %s
// GROUP-EMPTY: <GROUPS>
// GROUP-EMPTY-NEXT: <\GROUPS>

// RUN: %swift -emit-module -o %t.mod/swift_mod_syn.swiftmodule %S/Inputs/swift_mod_syn.swift -parse-as-library -disable-implicit-concurrency-module-import -disable-implicit-string-processing-module-import
// RUN: %sourcekitd-test -req=interface-gen-open -module swift_mod_syn -- -Xfrontend -disable-implicit-concurrency-module-import -Xfrontend -disable-implicit-string-processing-module-import  -I %t.mod == -req=cursor -pos=4:7 %s -- -Xfrontend -disable-implicit-concurrency-module-import -Xfrontend -disable-implicit-string-processing-module-import  %s -I %t.mod | %FileCheck -check-prefix=SYNTHESIZED-USR1 %s
// SYNTHESIZED-USR1: s:SMsSkRzSL7ElementSTRpzrlE4sortyyF::SYNTHESIZED::s:Sa

// RUN: %sourcekitd-test -req=interface-gen-open -module Swift -synthesized-extension \
// RUN: 	== -req=find-usr -usr "s:SMsSkRzSL7ElementSTRpzrlE4sortyyF::SYNTHESIZED::s:Sa" | %FileCheck -check-prefix=SYNTHESIZED-USR2 %s
// SYNTHESIZED-USR2-NOT: USR NOT FOUND

// RUN: %sourcekitd-test -req=interface-gen-open -module Swift \
// RUN: 	== -req=find-usr -usr "s:SMsSkRzSL7ElementSTRpzrlE4sortyyF::SYNTHESIZED::s:Sa::SYNTHESIZED::USRDOESNOTEXIST" | %FileCheck -check-prefix=SYNTHESIZED-USR3 %s
// SYNTHESIZED-USR3-NOT: USR NOT FOUND


// Test we can generate the interface of a module loaded via a .swiftinterface file correctly

// RUN: %empty-directory(%t.mod)
// RUN: %swift -emit-module -o /dev/null -emit-module-interface-path %t.mod/swift_mod.swiftinterface -O %S/Inputs/swift_mod.swift -parse-as-library -disable-implicit-concurrency-module-import -disable-implicit-string-processing-module-import
// RUN: %sourcekitd-test -req=interface-gen -module swift_mod -- -Xfrontend -disable-implicit-concurrency-module-import -Xfrontend -disable-implicit-string-processing-module-import  -I %t.mod -module-cache-path %t.mod/mcp > %t.response
// RUN: %diff -u %s.from_swiftinterface.response %t.response

// Separately test whether the optional declarations array contains the expected information from Inputs/swift_mod.swift
// RUN: %sourcekitd-test -req=interface-gen -req-opts=enabledeclarations=true -module swift_mod -- -Xfrontend -disable-implicit-concurrency-module-import -Xfrontend -disable-implicit-string-processing-module-import  -I %t.mod -module-cache-path %t.mod/mcp | %FileCheck -check-prefix=CHECK-DECLARATIONS-ARRAY %s
// check that the other arrays are still there as normal, by checking for a unique identifying member in each
// CHECK-DECLARATIONS-ARRAY-DAG: key.kind:{{.*}}ref.associatedtype
// CHECK-DECLARATIONS-ARRAY-DAG: key.kind:{{.*}}syntaxtype
// CHECK-DECLARATIONS-ARRAY-DAG: key.substructure

// CHECK-DECLARATIONS-ARRAY: {{^}}]{{$}}

// public class MyClass
// CHECK-DECLARATIONS-ARRAY: key.kind:{{.*}}class
// CHECK-DECLARATIONS-ARRAY-NEXT: key.usr
// CHECK-DECLARATIONS-ARRAY-SAME: swift_mod
// CHECK-DECLARATIONS-ARRAY-SAME: MyClass

// public func pub_method
// CHECK-DECLARATIONS-ARRAY: key.kind:{{.*}}method.instance
// CHECK-DECLARATIONS-ARRAY-NEXT: key.usr
// CHECK-DECLARATIONS-ARRAY-SAME: swift_mod
// CHECK-DECLARATIONS-ARRAY-SAME: MyClass
// CHECK-DECLARATIONS-ARRAY-SAME: pub_method

// CHECK-DECLARATIONS-ARRAY-NOT: int_method
// CHECK-DECLARATIONS-ARRAY-NOT: fp_method
// CHECK-DECLARATIONS-ARRAY-NOT: priv_method

// public protocol MyProto
// CHECK-DECLARATIONS-ARRAY: key.kind:{{.*}}protocol
// CHECK-DECLARATIONS-ARRAY-NEXT: key.usr
// CHECK-DECLARATIONS-ARRAY-SAME: swift_mod
// CHECK-DECLARATIONS-ARRAY-SAME: MyProto

// associatedtype Assoc
// CHECK-DECLARATIONS-ARRAY: key.kind:{{.*}}associatedtype
// CHECK-DECLARATIONS-ARRAY-NEXT: key.usr
// CHECK-DECLARATIONS-ARRAY-SAME: swift_mod
// CHECK-DECLARATIONS-ARRAY-SAME: Assoc

// public func pub_function
// CHECK-DECLARATIONS-ARRAY: key.kind:{{.*}}function.free
// CHECK-DECLARATIONS-ARRAY-NEXT: key.usr
// CHECK-DECLARATIONS-ARRAY-SAME: swift_mod
// CHECK-DECLARATIONS-ARRAY-SAME: pub_function

// CHECK-DECLARATIONS-ARRAY-NOT: int_function
// CHECK-DECLARATIONS-ARRAY-NOT: fp_function
// CHECK-DECLARATIONS-ARRAY-NOT: priv_function
