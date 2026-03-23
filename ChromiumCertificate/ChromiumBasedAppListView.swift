//
//  ChromiumBasedAppListView.swift
//  ChromiumCertificate
//
//  Created by Astrian Zheng on 14/7/2025.
//

import SwiftUI

struct ChromiumBasedAppListView: View {
	@Binding var isPresented: Bool
	
	@State private var chromiumAppsList: [ChromiumApp]? = ChromiumDetector.cachedApps
	
	var body: some View {
		VStack(spacing: 0) {
			HStack {
				Text("LISTVIEW_TITLE").font(.headline)
				Spacer()
				Button {
					self.isPresented.toggle()
				} label: {
					Text("LISTVIEW_CLOSE")
				}
			}.padding()
			
			Divider()
			
			if let chromiumAppsList = chromiumAppsList {
				ScrollView {
					if chromiumAppsList.isEmpty {
						Text("LISTVIEW_NO_CHRIMIUM_APPS_FOUND").multilineTextAlignment(.center).padding()
					}
					VStack(spacing: 8) {
						ForEach(Array(chromiumAppsList.enumerated()), id: \.element.id) { index, chromiumApp in
							HStack {
								VStack(alignment: .leading) {
									HStack {
										if let isTahoeFixed = chromiumApp.isTahoeFixed {
											Text(isTahoeFixed ? "LISTVIEW_FIXED_INDICATOR" : "LISTVIEW_UNFIX_INDICATOR")
										}
										Text(chromiumApp.name).bold()
									}
									if let version = chromiumApp.electronVersion {
										Text("LISTVIEW_ELECTRON_VERSION_TAG \(version)")
											.font(.system(.caption, design: .monospaced))
									}
									Text(chromiumApp.path)
										.font(.system(.caption, design: .monospaced))
								}
								Spacer()
							}
							
							if index < chromiumAppsList.count - 1 {
								Divider()
							}
						}
					}.padding()

					if chromiumAppsList.contains(where: { $0.isTahoeFixed != nil }) {
						Divider()
						VStack(alignment: .leading, spacing: 4) {
							Text("LISTVIEW_PERFORMANCE_ISSUE_TITLE").font(.caption).bold()
							Text("LISTVIEW_PERFORMANCE_ISSUE_PARAGRAPH_1").font(.caption2)
							Text("LISTVIEW_PERFORMANCE_ISSUE_PARAGRAPH_2").font(.caption2)
						}.padding().frame(maxWidth: .infinity, alignment: .leading)
					}
				}
			} else {
				VStack {
					Spacer()
					ProgressView()
					Spacer()
				}
			}
		}.frame(width: 300).frame(minHeight: 0, maxHeight: 300)
		.onAppear {
			ChromiumDetector.detectChromiumApps { apps in
				self.chromiumAppsList = apps
			}
		}
	}
}

#Preview("中文") {
	ChromiumBasedAppListView(isPresented: .constant(true))
		.environment(\.locale, Locale(identifier: "zh-Hans"))
}

#Preview("English") {
	ChromiumBasedAppListView(isPresented: .constant(true))
		.environment(\.locale, Locale(identifier: "en"))
}

#Preview("日本語") {
	ChromiumBasedAppListView(isPresented: .constant(true))
		.environment(\.locale, Locale(identifier: "ja"))
}
