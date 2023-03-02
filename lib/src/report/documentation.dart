// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:collection/collection.dart';
import 'package:pana/src/package_context.dart';
import 'package:path/path.dart' as p;

import '../dartdoc_analyzer.dart';
import '../maintenance.dart';
import '../model.dart';
import '../pubspec.dart';

import '_common.dart';

Future<ReportSection> hasDocumentation(
    PackageContext context, Pubspec pubspec) async {
  final packageDir = context.packageDir;
  // TODO: run dartdoc for coverage

  final candidates = exampleFileCandidates(pubspec.name);
  // Because we care about the file-names case, we first list all files, and
  // then test for presence of candidates in that list.
  //
  // This should work on case-preserving but insensitive file-systems.
  final files = Directory(packageDir).listSync(recursive: true).map(
      (e) => p.posix.joinAll(p.split(p.relative(e.path, from: packageDir))));
  final examplePath = candidates.firstWhereOrNull(files.contains);
  final issues = <Issue>[
    if (examplePath == null)
      Issue(
        'No example found.',
        suggestion:
            'See [package layout](https://dart.dev/tools/pub/package-layout#examples) '
            'guidelines on how to add an example.',
      )
  ];

  final screenshotIssues = <Issue>[];
  final declaredScreenshots = pubspec.screenshots;

  final headline = declaredScreenshots.isNotEmpty
      ? 'Package has an example and has no issues with screenshots'
      : 'Package has an example';
  final screenshotResults = await context.screenshots;
  for (var result in screenshotResults) {
    screenshotIssues.addAll(result.problems.map(Issue.new));
  }

  issues.addAll(screenshotIssues);

  final status = screenshotIssues.isEmpty && examplePath != null
      ? ReportStatus.passed
      : ReportStatus.failed;
  final points = status == ReportStatus.passed ? 10 : 0;
  return makeSection(
    id: ReportSectionId.documentation,
    title: documentationSectionTitle,
    maxPoints: 10,
    subsections: [
      Subsection(headline, issues, points, 10, status),
    ],
    basePath: null,
  );
}
