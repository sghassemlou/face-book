//
//  ContentView.swift
//  face-book
//
//  Created by Fraser Lee on 2024-01-27.
//

import SwiftUI
import SwiftData

var personView : UIImageView = UIImageView()

struct PersonViewWrapper: UIViewRepresentable, Identifiable {
    let id = UUID()
    var image: UIImage?
    func makeUIView(context: Context) -> UIImageView {
        personView = UIImageView(frame: CGRect(x:300, y:500, width: 30, height: 30) )
        personView.backgroundColor = .blue
        personView.contentMode = .scaleAspectFill
        return personView
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        uiView.frame = CGRect(x:300, y:500, width: 30, height: 30)
        uiView.contentMode = .scaleAspectFill
        uiView.image = image
        uiView.contentMode = .scaleAspectFill
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    private var audioRecorder = AudioRecorder()
    
    var body: some View {
        // rounded rect taking up the top half of the screen with padding
        GeometryReader { geo in
            VStack(spacing:10){
                HostedViewController()
                    .frame(height: geo.size.height * (1/2))
                    .cornerRadius(25.0)


                GeometryReader{ geo1 in
                    VStack (alignment: .leading) {
                        HStack (alignment: .top) {
                            Button (action: toggleCam) {
                                Image(systemName: "camera.rotate.fill")
                                    .frame(width: 44, height: 44)
                                    .foregroundColor(.white)
                                    .background(.gray)
                                    .cornerRadius(13)
                                    .imageScale(.medium)
                            }

                            // Audio recording button
                            Button("Record Audio") {
                                if audioRecorder.isRecording {
                                    audioRecorder.stopRecording()
                                } else {
                                    audioRecorder.startRecording()
                                }
                            }
                        }

                        HStack {
                            VStack{
                                Text("hello world.")
                                    .font(.system(size: 25, weight: .regular, design: .rounded))

                                PersonViewWrapper()
//                                    .frame(width: 200, height: 200)
                                    .cornerRadius(25.0)
                            }.frame(width: geo.size.width)
                        }

                    }.frame(width: geo.size.width)
                }
                .frame(height: geo.size.height * (1/2))
            }
        }.padding(.horizontal)
    }

    private func toggleCam() {
        vc.setupVideoInput()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
