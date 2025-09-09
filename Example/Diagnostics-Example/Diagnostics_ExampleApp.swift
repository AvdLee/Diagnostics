//
//  Diagnostics_ExampleApp.swift
//  Diagnostics-Example
//
//  Created by A.J. van der Lee on 30/06/2025.
//

import SwiftUI
import Diagnostics

@main
struct Diagnostics_ExampleApp: App {
    
    enum ExampleError: Error {
        case missingData
    }

    enum ExampleLocalizedError: LocalizedError {
        case missingLocalizedData

        var localizedDescription: String {
            return "Missing localized data"
        }
    }
    
    init() {
        do {
            try DiagnosticsLogger.setup()
        } catch {
            print("Failed to setup the Diagnostics Logger")
        }

        DiagnosticsLogger.log(message: "Application started")
        DiagnosticsLogger.log(error: ExampleError.missingData)
        DiagnosticsLogger.log(error: ExampleLocalizedError.missingLocalizedData)
        //  swiftlint:disable:next line_length
        DiagnosticsLogger.log(message: "A very long string: Lorem ipsum dolor sit amet, consectetur adipiscing elit. Quisque condimentum facilisis arcu, at fermentum diam fermentum in. Nullam lectus libero, tincidunt et risus vel, feugiat vulputate nunc. Nunc malesuada congue risus fringilla lacinia. Aliquam suscipit nulla nec faucibus mattis. Suspendisse quam nunc, interdum vel dapibus in, vulputate ac enim. Morbi placerat commodo leo, nec condimentum eros dictum sit amet. Vivamus maximus neque in dui rutrum, vel consectetur metus mollis. Nulla ultricies sodales viverra. Etiam ut velit consectetur, consectetur turpis eu, volutpat purus. Maecenas vitae consectetur tortor, at eleifend lacus. Nullam sed augue vel purus mollis sagittis at sed dui. Quisque faucibus fermentum lectus eget porttitor. Phasellus efficitur aliquet lobortis. Suspendisse at lectus imperdiet, sollicitudin arcu non, interdum diam. Sed ornare ante dolor. In pretium auctor sem, id vestibulum sem molestie in.")
    }
    
    var body: some Scene {
        WindowGroup {
            #if os(macOS)
                ContentView_macOS()
            #else
                ContentView_iOS()
            #endif
        }
    }
}

func performCrash() {
    /// Swift exceptions can't be catched yet, unfortunately.
    let array = NSArray(array: ["Antoine", "Boris", "Kaira"])
    print(array.object(at: 4)) // Classic index out of bounds crash
}
