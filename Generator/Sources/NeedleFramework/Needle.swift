//
//  Copyright (c) 2018. Uber Technologies
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Concurrency
import Foundation

let needleModuleName = "NeedleFoundation"
let defaultTimeout = 30.0

/// The entry point to Needle, providing all the functionalities of the system.
public class Needle {

    /// Parse Swift source files by recurively scanning the given directories
    /// excluding files with specified suffixes. Generate the necessary
    /// dependency provider code and export to the specified destination path.
    ///
    /// - parameter sourceRootPaths: The directories of source files to parse.
    /// - parameter exclusionSuffixes: The file suffixes to exclude from parsing.
    /// - parameter additionalImports: The additional import statements to add
    /// to the ones parsed from source files.
    /// - parameter headerDocPath: The path to custom header doc file to be
    /// included at the top of the generated file.
    /// - parameter destinationPath: The path to export generated code to.
    public static func generate(from sourceRootPaths: [String], excludingFilesWith exclusionSuffixes: [String], with additionalImports: [String], _ headerDocPath: String?, to destinationPath: String) {
        let sourceRootUrls = sourceRootPaths.map { (path: String) -> URL in
            URL(fileURLWithPath: path)
        }
        #if DEBUG
            let executor: SequenceExecutor = ProcessInfo().environment["SINGLE_THREADED"] != nil ? SerialSequenceExecutor() : ConcurrentSequenceExecutor(name: "Needle.generate", qos: .userInteractive)
        #else
            let executor = ConcurrentSequenceExecutor(name: "Needle.generate", qos: .userInteractive)
        #endif
        let parser = DependencyGraphParser()
        do {
            let (components, imports) = try parser.parse(from: sourceRootUrls, excludingFilesWith: exclusionSuffixes, using: executor)
            let exporter = DependencyGraphExporter()
            try exporter.export(components, with: imports + additionalImports, to: destinationPath, using: executor, include: headerDocPath)
        } catch DependencyGraphParserError.timeout(let sourcePath) {
            fatalError("Parsing Swift source file at \(sourcePath) timed out.")
        } catch DependencyGraphExporterError.timeout(let componentName) {
            fatalError("Generating dependency provider for \(componentName) timed out.")
        } catch DependencyGraphExporterError.unableToWriteFile(let outputFile) {
            fatalError("Failed to export contents to \(outputFile)")
        } catch {
            fatalError("Unknown error \(error).")
        }
    }
}
