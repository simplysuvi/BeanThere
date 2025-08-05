import SwiftUI

struct LaunchView: View {
    @State private var isActive = false
    
    var body: some View {
        ZStack {
            if isActive {
                ContentView()
            } else {
                ZStack {
                    Theme.background.edgesIgnoringSafeArea(.all)
                    VStack {
                        Image("LaunchLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(radius: 10)

                        Text("BeanThere")
                            .font(.system(size: 32, weight: .bold, design: .serif))
                            .fontWeight(.bold)
                            .foregroundColor(Theme.text)
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation {
                            self.isActive = true
                        }
                    }
                }
            }
        }
    }
}

struct LaunchView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchView()
    }
}
