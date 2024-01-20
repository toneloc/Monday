//
//  StartView.swift
//  LDKNodeMonday
//
//  Created by Matthew Ramsden on 5/17/23.
//

import BitcoinUI
import LDKNode
import SimpleToast
import SwiftUI

struct StartView: View {
    @ObservedObject var viewModel: StartViewModel
    @State private var showingStartViewErrorAlert = false
    @State var startViewError: MondayError?

    var body: some View {

        ZStack {
            Color(uiColor: UIColor.systemBackground)

            VStack {
                if viewModel.isStarted {
                    TabHomeView(viewModel: .init())
                } else {
                    //                    ProgressView {
                    //                        HStack {
                    //                            Image(systemName: "bolt.fill")
                    //                                .foregroundColor(
                    //                                    Color(red: 119 / 255, green: 243 / 255, blue: 205 / 255)
                    //                                )
                    //                            Text("Starting Node")
                    //                        }
                    //                        .font(.caption)
                    //                    }
                    withAnimation {
                        Image(systemName: "bolt.horizontal")
                            .symbolEffect(
                                .pulse.wholeSymbol
                            )
                            .foregroundColor(
                                Color(red: 119 / 255, green: 243 / 255, blue: 205 / 255)
                            )
                    }
                }
            }
            .padding()
            .tint(viewModel.networkColor)
            .onAppear {
                Task {
                    do {
                        try await viewModel.start()
                        viewModel.getColor()
                    } catch let error as NodeError {
                        let errorString = handleNodeError(error)
                        DispatchQueue.main.async {
                            self.startViewError = .init(
                                title: errorString.title,
                                detail: errorString.detail
                            )
                        }
                    } catch {
                        DispatchQueue.main.async {
                            self.startViewError = .init(
                                title: "Unexpected error",
                                detail: error.localizedDescription
                            )
                        }
                    }
                }
            }
            .alert(isPresented: $showingStartViewErrorAlert) {
                Alert(
                    title: Text(viewModel.startViewError?.title ?? "Unknown"),
                    message: Text(viewModel.startViewError?.detail ?? ""),
                    dismissButton: .default(Text("OK")) {
                        viewModel.startViewError = nil
                    }
                )
            }

        }
        .ignoresSafeArea()

    }

}

struct StartView_Previews: PreviewProvider {
    static var previews: some View {
        StartView(viewModel: .init())
        StartView(viewModel: .init())
            .environment(\.colorScheme, .dark)
    }
}
