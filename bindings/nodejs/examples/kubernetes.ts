/**
 * Kubernetes manifest generation example
 */

import { render } from '../src/index';

interface AppConfig {
  name: string;
  namespace: string;
  replicas: number;
  image: string;
  tag: string;
  port: number;
  resources: {
    limits: {
      cpu: string;
      memory: string;
    };
    requests: {
      cpu: string;
      memory: string;
    };
  };
  env: Record<string, string>;
}

const template = `apiVersion: apps/v1
kind: Deployment
metadata:
  name: $name
  namespace: $namespace
  labels:
    app: $name
spec:
  replicas: $replicas
  selector:
    matchLabels:
      app: $name
  template:
    metadata:
      labels:
        app: $name
    spec:
      containers:
        - name: $name
          image: ${image}:${tag}
          ports:
            - containerPort: $port
              protocol: TCP
          env:
@for key, value in pairs(env)
            - name: $key
              value: "$value"
@end
          resources:
            limits:
              cpu: $resources.limits.cpu
              memory: $resources.limits.memory
            requests:
              cpu: $resources.requests.cpu
              memory: $resources.requests.memory
---
apiVersion: v1
kind: Service
metadata:
  name: $name
  namespace: $namespace
spec:
  selector:
    app: $name
  ports:
    - port: $port
      targetPort: $port
      protocol: TCP
  type: ClusterIP`;

const config: AppConfig = {
  name: 'myapp',
  namespace: 'production',
  replicas: 3,
  image: 'myapp',
  tag: 'v1.2.3',
  port: 8080,
  resources: {
    limits: {
      cpu: '1000m',
      memory: '512Mi',
    },
    requests: {
      cpu: '100m',
      memory: '128Mi',
    },
  },
  env: {
    NODE_ENV: 'production',
    LOG_LEVEL: 'info',
    API_URL: 'https://api.example.com',
  },
};

console.log('=== Kubernetes Deployment ===\n');
const manifest = render(template, config);
console.log(manifest);

// Example: Generate multiple environments
console.log('\n\n=== Multi-Environment Generation ===\n');

const environments = ['dev', 'staging', 'prod'];

for (const env of environments) {
  const envConfig: AppConfig = {
    ...config,
    namespace: env,
    replicas: env === 'prod' ? 5 : 2,
    env: {
      ...config.env,
      NODE_ENV: env === 'dev' ? 'development' : 'production',
    },
  };

  console.log(`--- ${env.toUpperCase()} ---`);
  const envManifest = render(template, envConfig);
  console.log(envManifest.split('\n').slice(0, 10).join('\n'));
  console.log('...\n');
}
