//
//  AppDelegate.swift
//  SplitBenchmarkHost
//
//  Blank host app for the SplitBenchmark test bundle. A direct launch with `-benchScenario` runs one scenario
//  and writes the CSV to Documents.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()
        self.window = window
        BenchmarkDirectLaunch.startIfRequested()
        return true
    }
}
