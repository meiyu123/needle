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

/// The task that generates the declarations of the dependency providers
/// for a specific component, for all of its ancestor paths.
class DependencyProviderDeclarerTask: AbstractTask<[DependencyProvider]> {

    /// Initializer.
    ///
    /// - parameter component: The component that requires the dependency
    /// provider.
    init(component: Component) {
        self.component = component
    }

    /// Execute the task and returns the in-memory dependency graph data models.
    ///
    /// - returns: The list of `DependencyProvider`.
    override func execute() -> [DependencyProvider] {
        return ancestorPaths(for: component)
            .map { (path: [Component]) -> DependencyProvider in
                return DependencyProvider(path: path, dependency: component.dependency)
            }
    }

    // MARK: - Private

    private let component: Component

    private func ancestorPaths(for component: Component) -> [[Component]] {
        if component.parents.isEmpty {
            return [[component]]
        } else {
            var allPaths = [[Component]]()
            for parent in component.parents {
                let parentAncestorPaths = ancestorPaths(for: parent)
                    .map { (path: [Component]) -> [Component] in
                        return path + [component]
                    }
                allPaths.append(contentsOf: parentAncestorPaths)
            }
            return allPaths
        }
    }
}
