//
//  GenericStateView.swift
//  BitcoinApp
//
//  Created by Vedant Patil on 27/09/25.
//

import SwiftUI

struct GenericStateView: View {
    let icon: String?
    let title: String?
    let subtitle: String?
    let buttonTitle: String?
    let buttonAction: (() -> Void)?
    let isLoading: Bool
    let iconColor: Color
    let buttonColor: Color
    
    init(icon: String? = nil, title: String? = nil, subtitle: String? = nil, buttonTitle: String? = nil, buttonAction: (() -> Void)? = nil, isLoading: Bool = false, iconColor: Color = .blue, buttonColor: Color = .blue) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.buttonTitle = buttonTitle
        self.buttonAction = buttonAction
        self.isLoading = isLoading
        self.iconColor = iconColor
        self.buttonColor = buttonColor
    }
    
    var body: some View {
        VStack(spacing: 20) {
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
            } else if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 60))
                    .foregroundColor(iconColor)
            }
            
            if let title = title {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
            }
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if let buttonTitle = buttonTitle, let buttonAction = buttonAction {
                Button(buttonTitle) {
                    buttonAction()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(buttonColor)
                .cornerRadius(12)
            }
        }
        .padding()
    }
    
}
