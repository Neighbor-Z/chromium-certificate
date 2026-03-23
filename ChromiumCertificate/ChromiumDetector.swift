//
//  ChromiumDetector.swift
//  ChromiumCertificate
//
//  Created by Astrian Zheng on 14/7/2025.
//

import Foundation

struct ChromiumApp: Identifiable {
	let id = UUID()
	let name: String
	let type: ChromiumType
	let path: String
	let electronVersion: String?
	let isTahoeFixed: Bool?
}

enum ChromiumType: String, CaseIterable {
	case electron = "Electron"
	case chromium = "Chromium"
	case chromiumLibrary = "Chromium库"
	case electronIdentifier = "Electron标识"
}

class ChromiumDetector {
    
    static var cachedApps: [ChromiumApp]?

    static func detectChromiumApps(forceReload: Bool = false, completion: @escaping ([ChromiumApp]) -> Void) {
        if !forceReload, let cached = cachedApps {
            DispatchQueue.main.async { completion(cached) }
            return
        }

        
        DispatchQueue.global(qos: .userInitiated).async {
            var chromiumApps: [ChromiumApp] = []
            let fileManager = FileManager.default
            let applicationsURL = URL(fileURLWithPath: "/Applications")
            
            do {
                let appURLs = try fileManager.contentsOfDirectory(
                    at: applicationsURL,
                    includingPropertiesForKeys: [.isDirectoryKey],
                    options: [.skipsHiddenFiles]
                )
                
                for appURL in appURLs {
                    if appURL.pathExtension == "app" {
                        if let chromiumApp = analyzeApp(at: appURL) {
                            chromiumApps.append(chromiumApp)
                        }
                    }
                }
            } catch {
                print("Error reading applications directory: \(error)")
            }
            
            let sortedApps = chromiumApps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            DispatchQueue.main.async {
                self.cachedApps = sortedApps
                completion(sortedApps)
            }
        }
    }
    
    private static func analyzeApp(at appURL: URL) -> ChromiumApp? {
        let appName = appURL.deletingPathExtension().lastPathComponent
        let contentsURL = appURL.appendingPathComponent("Contents")
        let frameworksURL = contentsURL.appendingPathComponent("Frameworks")
        let infoPlistURL = contentsURL.appendingPathComponent("Info.plist")
        
        // 检查 Electron Framework
        let electronFrameworkURL = frameworksURL.appendingPathComponent("Electron Framework.framework")
        if FileManager.default.fileExists(atPath: electronFrameworkURL.path) {
            let (version, isFixed) = getElectronVersionInfo(at: electronFrameworkURL)
            return ChromiumApp(name: appName, type: .electron, path: appURL.path, electronVersion: version, isTahoeFixed: isFixed)
        }
        
        // 检查 Chromium 相关框架
        if hasChromiumFrameworks(at: frameworksURL) {
            return ChromiumApp(name: appName, type: .chromium, path: appURL.path, electronVersion: nil, isTahoeFixed: nil)
        }
        
        // 检查可执行文件是否链接到 Chromium 库
        let executableURL = contentsURL.appendingPathComponent("MacOS").appendingPathComponent(appName)
        if hasChromiumLibraries(executablePath: executableURL.path) {
            return ChromiumApp(name: appName, type: .chromiumLibrary, path: appURL.path, electronVersion: nil, isTahoeFixed: nil)
        }
        
        // 检查 Info.plist 中的 Electron 标识
        if hasElectronIdentifier(infoPlistPath: infoPlistURL.path) {
            return ChromiumApp(name: appName, type: .electronIdentifier, path: appURL.path, electronVersion: nil, isTahoeFixed: nil)
        }
        
        return nil
    }
    
    private static func hasChromiumFrameworks(at frameworksURL: URL) -> Bool {
        do {
            let frameworks = try FileManager.default.contentsOfDirectory(atPath: frameworksURL.path)
            return frameworks.contains { $0.localizedCaseInsensitiveContains("chromium") }
        } catch {
            return false
        }
    }
    
    private static func hasChromiumLibraries(executablePath: String) -> Bool {
        guard FileManager.default.fileExists(atPath: executablePath) else { return false }
        
        let task = Process()
        task.launchPath = "/usr/bin/otool"
        task.arguments = ["-L", executablePath]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            return output.localizedCaseInsensitiveContains("chromium")
        } catch {
            return false
        }
    }
    
    private static func hasElectronIdentifier(infoPlistPath: String) -> Bool {
        guard FileManager.default.fileExists(atPath: infoPlistPath),
              let data = try? Data(contentsOf: URL(fileURLWithPath: infoPlistPath)),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
              let bundleId = plist["CFBundleIdentifier"] as? String else {
            return false
        }
        return bundleId.localizedCaseInsensitiveContains("electron")
    }

    private static func getElectronVersionInfo(at frameworkURL: URL) -> (version: String?, isFixed: Bool?) {
        let infoPlistURL = frameworkURL.appendingPathComponent("Resources/Info.plist")
        guard FileManager.default.fileExists(atPath: infoPlistURL.path),
              let data = try? Data(contentsOf: infoPlistURL),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
              let versionString = plist["CFBundleVersion"] as? String else {
            return (nil, nil)
        }
        
        let trimmed = versionString.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return (nil, nil) }
        
        return (trimmed, isElectronVersionFixed(trimmed))
    }

    private static func isElectronVersionFixed(_ versionString: String) -> Bool {
        let components = versionString.split(separator: ".").compactMap { Int($0) }
        guard components.count >= 2 else { return false }

        let major = components[0]
        let minor = components[1]
        let patch = components.count > 2 ? components[2] : 0

        if major > 39 { return true }
        if major == 39 && minor >= 0 { return true }
        if major == 38 && minor > 2 { return true }
        if major == 38 && minor == 2 && patch >= 0 { return true }
        if major == 37 && minor > 6 { return true }
        if major == 37 && minor == 6 && patch >= 0 { return true }
        if major == 36 && minor > 9 { return true }
        if major == 36 && minor == 9 && patch >= 2 { return true }

        return false
    }
    
}
