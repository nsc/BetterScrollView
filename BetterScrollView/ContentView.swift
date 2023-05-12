//
//  ContentView.swift
//  BetterScrollView
//
//  Created by Nico Schmidt on 05.05.23.
//

import SwiftUI

struct ContentView: View {
    @State var items: [Int] = [0,1,2,3,4,5]

    var body: some View {
        ScrollViewReader { proxy in
            NavigationStack {
                HStack {
                    BetterScrollView {
                        ForEach(items, id: \.self) { i in
                            VStack {
                                Image(systemName: "globe")
                                    .imageScale(.large)
                                    .foregroundColor(.accentColor)
                                Text("Hello, world!")
                                    .foregroundColor(Color(hue: (Double(i) / 18).truncatingRemainder(dividingBy: 1), saturation: 1, brightness: 0.8))
                            }
                            .id(i)
                        }
                        .navigationTitle(["Bla", "Blub"].randomElement()!)
                    }
                    .border(.green)
                    
                    ScrollView([.horizontal, .vertical]) {
                        ForEach(items, id: \.self) { i in
                            VStack {
                                Image(systemName: "globe")
                                    .imageScale(.large)
                                    .foregroundColor(.accentColor)
                                Text("Hello, world!")
                                    .foregroundColor(Color(hue: (Double(i) / 18).truncatingRemainder(dividingBy: 1), saturation: 1, brightness: 0.8))
                            }
                            .id(i)
                        }
                    }
                    .border(.red)
                }
            }
            .scrollIndicators(.visible)
            .toolbar {
                ToolbarItem {
                    Button("Add Something") {
                        items.append(items.count)
                    }
                }
                ToolbarItem {
                    Button("Scroll to Bottom") {
                        proxy.scrollTo(items.last!)
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
