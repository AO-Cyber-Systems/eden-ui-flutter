// MOVED IN TRD 23-02.
//
// The implementation now lives at `lib/testing/semantics_geometry.dart` and
// ships to consumers as part of `package:eden_ui_flutter/testing.dart`.
//
// This file is a re-export shim so 23-01's tests
// (`test/ui_oracle/semantics_geometry_test.dart`) keep their relative import
// and stay byte-identical. There is exactly ONE implementation; a second copy
// here would drift and only one copy would get the next fix.
export 'package:eden_ui_flutter/testing/semantics_geometry.dart';
