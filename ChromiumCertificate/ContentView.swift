//
//  ContentView.swift
//  ChromiumCertificate
//
//  Created by Astrian Zheng on 14/7/2025.
//

import SwiftUI

struct StrokeText: ViewModifier {
	var strokeSize: CGFloat = 1
	var strokeColor: Color = .black
	
	func body(content: Content) -> some View {
		content
			.background(
				Rectangle()
					.foregroundColor(strokeColor)
					.mask(content)
					.blur(radius: strokeSize)
			)
	}
}

extension View {
	func stroke(color: Color = .black, width: CGFloat = 1) -> some View {
		modifier(StrokeText(strokeSize: width, strokeColor: color))
	}
}

struct ContentView: View {
	@State private var count: Int? = nil
	@State private var presentSheet: Bool = false
	@Environment(\.locale) private var locale
	
	var body: some View {
		ZStack {
			Image("AnnouncementBg").resizable().frame(width: 640, height: 480).offset(x: 0, y: -12)
			VStack {
				if let count = count {
					Text("MAINVIEW_CHROMIUM_COUNTER \(count)")
						.multilineTextAlignment(.center)
						.font(.system(size: 35, weight: .semibold))
						.foregroundColor(Color("TextColor"))
						.stroke(color: Color("TextBorderColor"), width: 5)
						.padding(.horizontal)
				} else {
					ProgressView()
						.scaleEffect(1.5)
						.padding()
				}
				
				Button {
					self.presentSheet.toggle()
				} label: {
					Text("MAINVIEW_SEE_LIST").font(.system(size: 20)).padding(.horizontal).padding(.vertical, 8)
				}
				.disabled(count == nil)
				.buttonStyle(.borderedProminent)
				.tint(.red)
				.sheet(isPresented: self.$presentSheet) {
					ChromiumBasedAppListView(isPresented: self.$presentSheet)
				}
			}
		}
		.frame(width: 640, height: 440)
		.onAppear {
			ChromiumDetector.detectChromiumApps { apps in
				self.count = apps.count
			}
		}
	}
}

#Preview("中文") {
    ContentView()
        .environment(\.locale, Locale(identifier: "zh-Hans"))
}

#Preview("English") {
    ContentView()
        .environment(\.locale, Locale(identifier: "en"))
}

#Preview("日本語") {
    ContentView()
        .environment(\.locale, Locale(identifier: "ja"))
}
