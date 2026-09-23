//
//  QRCard.swift
//  air
//
//  Created by Dylan Karunanayake on 11/9/2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct QRCard: View {
    @State private var inputText: String = "https://stardance.hackclub.com"
    @State private var fgColor: Color = .black
    @State private var bgColor: Color = .white
    @State private var dotStyle: QRDotStyle = .square
    @State private var eyeBorderStyle: QREyeBorderStyle = .square
    @State private var eyeCenterStyle: QREyeCenterStyle = .square
    @State private var qrImage: NSImage? = nil
    @State private var regenerateTask: Task<Void, Never>? = nil

    var body: some View {
        Card {
//            VStack(alignment: .center) {
                HStack(alignment: .center, spacing: 16) {
                    VStack {
                        qrPreview
                        HStack {
                            colorSwatch(selection: $fgColor)
                                .padding(.trailing, 20)
                            colorSwatch(selection: $bgColor)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        contentField
                        
                        VStack(alignment: .center, spacing: 10) {
                            styleRow(title: "Dots", selection: $dotStyle, options: QRDotStyle.allCases, icon: dotIcon)
                            styleRow(title: "Border", selection: $eyeBorderStyle, options: QREyeBorderStyle.allCases, icon: eyeBorderIcon)
                            styleRow(title: "Center", selection: $eyeCenterStyle, options: QREyeCenterStyle.allCases, icon: eyeCenterIcon)
                        }
                        
                        exportButton
                            .padding(.top, 4)
                    }
                }
                .padding(20)
                .onChange(of: inputText) { _, _ in scheduleRegenerate() }
                .onChange(of: fgColor) { _, _ in scheduleRegenerate() }
                .onChange(of: bgColor) { _, _ in scheduleRegenerate() }
                .onChange(of: dotStyle) { _, _ in scheduleRegenerate() }
                .onChange(of: eyeBorderStyle) { _, _ in scheduleRegenerate() }
                .onChange(of: eyeCenterStyle) { _, _ in scheduleRegenerate() }
                .onAppear { regenerate() }
            }
//        }
    }

    private var qrPreview: some View {
        ZStack {
            if let qrImage {
                Image(nsImage: qrImage)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(bgColor)
                    )
            } else {
                ContentUnavailableView("No Content", systemImage: "qrcode")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.background)
                    )
            }
        }
        .frame(width: 200, height: 200)
    }

    private var contentField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Content")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            TextField("Enter URL or text", text: $inputText)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func colorSwatch(selection: Binding<Color>) -> some View {
        ColorPicker("", selection: selection, supportsOpacity: false)
            .labelsHidden()
            .frame(width: 26, height: 26)
//            .conditionalGlassEffect()
    }

    private var exportButton: some View {
        Button {
            exportImage()
        } label: {
            Label("Export QR Code", systemImage: "square.and.arrow.up")
                .font(.system(size: 13, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
        }
        .conditionalGlassButton()
        .controlSize(.large)
        .disabled(qrImage == nil)
    }

    @ViewBuilder
    private func styleRow<T: Hashable & CaseIterable & Identifiable>(
        title: String,
        selection: Binding<T>,
        options: [T],
        icon: @escaping (T, Bool) -> AnyView
    ) -> some View where T.AllCases: RandomAccessCollection {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                ForEach(options) { option in
                    let isSelected = option == selection.wrappedValue
                    Button {
                        withAnimation(.easeOut(duration: 0.12)) {
                            selection.wrappedValue = option
                        }
                    } label: {
                        icon(option, isSelected)
                            .frame(width: 34, height: 34)
                    }
                    .conditionalGlassButton()
                }
            }
        }
    }

    private func dotIcon(_ style: QRDotStyle, _ selected: Bool) -> AnyView {
        let color = selected ? Color.white : Color.primary.opacity(0.85)
        let grid = 3
        return AnyView(
            VStack(spacing: 2) {
                ForEach(0..<grid, id: \.self) { r in
                    HStack(spacing: 2) {
                        ForEach(0..<grid, id: \.self) { c in
                            let on = (r + c) % 2 == 0
                            Group {
                                switch style {
                                case .square:
                                    Rectangle().fill(on ? color : .clear)
                                case .rounded:
                                    RoundedRectangle(cornerRadius: 2).fill(on ? color : .clear)
                                case .dots:
                                    Circle().fill(on ? color : .clear)
                                }
                            }
                            .frame(width: 5, height: 5)
                        }
                    }
                }
            }
        )
    }

    private func eyeBorderIcon(_ style: QREyeBorderStyle, _ selected: Bool) -> AnyView {
        let color = selected ? Color.white : Color.primary.opacity(0.85)
        return AnyView(
            Group {
                switch style {
                case .square:
                    Rectangle().stroke(color, lineWidth: 2)
                case .rounded:
                    RoundedRectangle(cornerRadius: 6).stroke(color, lineWidth: 2)
                case .circle:
                    Circle().stroke(color, lineWidth: 2)
                }
            }
            .frame(width: 18, height: 18)
        )
    }

    private func eyeCenterIcon(_ style: QREyeCenterStyle, _ selected: Bool) -> AnyView {
        let color = selected ? Color.white : Color.primary.opacity(0.85)
        return AnyView(
            ZStack {
                RoundedRectangle(cornerRadius: 6).stroke(color, lineWidth: 2)
                    .frame(width: 18, height: 18)
                switch style {
                case .square:
                    Rectangle().fill(color).frame(width: 7, height: 7)
                case .rounded:
                    RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 7, height: 7)
                case .circle:
                    Circle().fill(color).frame(width: 7, height: 7)
                }
            }
        )
    }

    private func scheduleRegenerate() {
        regenerateTask?.cancel()
        regenerateTask = Task {
            try? await Task.sleep(nanoseconds: 150_000_000)
            guard !Task.isCancelled else { return }
            regenerate()
        }
    }

    private func regenerate() {
        qrImage = QRGenerator.generate(
            from: inputText,
            foregroundColor: NSColor(fgColor),
            backgroundColor: NSColor(bgColor),
            dotStyle: dotStyle,
            eyeBorderStyle: eyeBorderStyle,
            eyeCenterStyle: eyeCenterStyle
        )
    }

    private func exportImage() {
        guard let qrImage else { return }

        let panel = NSSavePanel()
        panel.title = "Export QR Code"
        panel.allowedContentTypes = [.png, .pdf]
        panel.nameFieldStringValue = "qr-code"
        panel.canCreateDirectories = true

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }

            let data: Data?
            switch url.pathExtension.lowercased() {
            case "pdf":
                data = pdfData(for: qrImage)
            default:
                data = pngData(for: qrImage)
            }

            guard let data else { return }
            do {
                try data.write(to: url)
            } catch {
                NSLog("QR export failed: \(error.localizedDescription)")
            }
        }
    }

    private func pngData(for image: NSImage) -> Data? {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
    }

    private func pdfData(for image: NSImage) -> Data? {
        let size = image.size
        var mediaBox = CGRect(origin: .zero, size: size)
        let pdfData = NSMutableData()

        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
              let ctx = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { return nil }

        ctx.beginPDFPage(nil)
        let nsContext = NSGraphicsContext(cgContext: ctx, flipped: false)
        let priorContext = NSGraphicsContext.current
        NSGraphicsContext.current = nsContext
        image.draw(in: mediaBox, from: .zero, operation: .sourceOver, fraction: 1.0)
        NSGraphicsContext.current = priorContext
        ctx.endPDFPage()
        ctx.closePDF()

        return pdfData as Data
    }
}
